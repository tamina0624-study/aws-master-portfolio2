
## 🚀 プロジェクト仕様書：EKS DevSecOps Pipeline

### 1. システム概要

Reactで構築されたフロントエンドアプリケーションを、
AWSのマネージドKubernetesサービス（EKS）上で安全かつ継続的にデプロイ・運用するプラットフォーム。

### 2. 技術スタック選定理由

| カテゴリ | 選定技術 | 選定理由（アピールポイント） |
| --- | --- | --- |
| **Frontend** | React | モダンなSPA開発の標準。ビルド成果物が静的ファイルなためコンテナ化に適している。 |
| **Container** | Docker / ECR | マルチステージビルドを採用し、実行環境の軽量化とセキュリティを両立。 |
| **Orchestrator** | Amazon EKS | エンタープライズでの採用実績が豊富。スケーラビリティと運用負荷軽減を両立。 |
| **IaC** | Terraform | クラウド基盤をコード管理し、再現性と変更履歴の透明性を確保。 |
| **Package Mgr** | Helm | Kubernetesリソースのテンプレート化とバージョン管理。 |
| **CI/CD** | GitHub Actions | 外部ツールとの親和性が高く、YAMLベースで透過的にパイプラインを定義可能。 |
| **Security** | Trivy | コンテナイメージの脆弱性スキャンを自動化し「シフトレフト」を体現。 |
| **Observability** | Prometheus / Grafana | インフラからアプリまでのメトリクスを一元管理。 |

---

### 3. アーキテクチャ設計

以下の3層構造で構築します。

1. **Infrastructure Layer (Terraform)**
* VPC (Public/Private Subnets, NAT Gateway)
* EKS Cluster (Managed Node Group)
* IAM Roles (IRSA: Podごとに必要なAWS権限を最小限に付与)


2. **Application Layer (Kubernetes)**
* Namespace: `devsecops-app`
* Service Type: LoadBalancer (AWS ALB Ingress Controllerの使用も検討)
* HPA (Horizontal Pod Autoscaler): 負荷に応じた自動スケーリング


3. **Pipeline Layer (DevSecOps)**
* **Git Push** → **Build** → **Trivy Scan** → **ECR Push** → **Helm Deploy**
* ※脆弱性が見つかった場合、デプロイを中止するゲート機能を実装。



---

### 4. セキュリティ要件（見せ場）

* **イメージの最小化:** `node:alpine` をベースに使用。
* **脆弱性診断:** `Critical`, `High` の脆弱性が1つでもあればビルドを失敗させる設定。
* **Secret管理:** APIキー等の機密情報は K8s Secrets または AWS Secrets Manager を利用（コードにベタ書きしない）。

---

### 5. 可視化（モニタリング）要件

* **Node/Podメトリクス:** CPU、メモリ使用率。
* **HTTP要求:** アプリへのトラフィック状況（オプション）。
* **アラート設定:** リソース逼迫時の可視化。

---

## 次のステップへの提案

この仕様に基づき、まずは **「1. Infrastructure Layer (Terraform)」** から着手するのが、土台ができて進めやすいかと思います。

それとも、まずは手元の `app` フォルダで **「Reactアプリ作成とDockerfileの作成（ローカル実行確認）」** から始めますか？

どちらから進めたいか、ご意向を教えてください。
