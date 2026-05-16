## 🏛️ 基本設計 (Basic Design)

### 1. アーキテクチャの全体像

インターネットからの入口を1点（ALB）に絞り、管理通信はすべてAWS内部ネットワークで完結させる「完全閉域・多層防御」スタイルです。

* **Public Area:** ALB（外部公開用窓口）と NAT Gateway（アウトバウンド専用）のみ配置。
* **Private Area:** EKS Worker Node、および AWS サービスと通信するための **VPC Endpoints** を配置。

### 2. コンポーネント構成表

| レイヤー | 採用技術 | 役割と設計のこだわり |
| --- | --- | --- |
| **Network** | VPC (Multi-AZ) | 2つのAZに跨る計4つのサブネット。可用性99.9%以上を意識。 |
| **Security** | **VPC Endpoints** | SSM管理通信をインターネットに一切出さないプライベート接続。 |
| **Compute** | Amazon EKS (v1.29) | マネージド型ノードグループによる運用負荷低減とセキュリティ担保。 |
| **Ingress** | AWS LB Controller | K8sリソース(Ingress)からALBを自動生成し、AWSネイティブな負荷分散を実現。 |
| **DevSecOps** | GitHub Actions + Trivy | 「シフトレフト」による脆弱性スキャンをパイプラインに統合。 |
| **Monitoring** | Prometheus / Grafana | インフラ・アプリの可観測性（Observability）の確保。 |

---

### 3. セキュリティ・管理方針

ここが今回の再設計の核心です。

* **ゼロ・オープンポート:**
* 外部からNodeへの直接アクセス（22番ポート等）は一切許可しない。
* 管理操作は IAM 認証ベースの **SSM Session Manager** を使用し、通信は VPC Endpoint 経由。


* **権限の分離 (Least Privilege):**
* Nodeにはイメージ取得と管理に必要な最小権限のみ付与。
* ALB作成などの強い権限は、専用の Service Account (IRSA) に限定。



---

### 4. ライフサイクル・フロー（通信の主軸）

1. **開発・デプロイ:** GitHub Actions → EKS API Server (IP制限付き) → ECR Image Pull。
2. **トラフィック:** User → ALB (Public) → Target Group → EKS Node (Private)。
3. **管理操作:** Admin → AWS Console/CLI → **SSM Endpoint** → EKS Node。
4. **監視:** Prometheus → Node Exporter (Metrics収集) → Grafana表示。

---

## 📂 更新された詳細フォルダ構成案

設計の深化に合わせて、Terraformの構成も少し詳細に分けます。

```text
11-DevSecOps-pipeLine/
├── terraform/
│   ├── vpc.tf            # VPC, Subnet, IGW, NATGW, Routes
│   ├── endpoints.tf      # SSM, EC2Messages 等の VPC Endpoints (New!)
│   ├── iam.tf            # NodeRole, ALBControllerRole (IRSA)
│   ├── eks.tf            # Cluster, NodeGroup, AccessEntry
│   ├── security_group.tf # ALB-SG, Node-SG, Endpoint-SG (整理)
│   ├── variables.tf
│   └── outputs.tf
```


### 1. システム構成図（論理構成）

システムの全体像は以下の通りです。

1. **開発者:** GitHubへコードをPush。
2. **CI/CD (GitHub Actions):**
* `Trivy` による脆弱性スキャンを実施。
* `Docker` イメージをビルドし、`Amazon ECR` へ格納。


3. **実行環境 (Amazon EKS):**
* `VPC` 内のプライベートサブネットで稼働。
* `Load Balancer (ALB)` を通じてインターネットに公開。


4. **監視 (Observability):**
* `Prometheus` でメトリクス収集、`Grafana` で可視化。

### 2. ネットワーク設計 (Network)

インフラエンジニアとしての腕の見せ所である、堅牢なネットワーク構成です。

| 項目 | 設定内容 | 備考 |
| --- | --- | --- |
| **VPC CIDR** | `10.11.0.0/16` | 他プロジェクトと重複しない帯域 |
| **Public Subnet** | 2つのAZ（例: ap-northeast-1a/c） | ALB、NAT Gateway用 |
| **Private Subnet** | 2つのAZ | EKS Worker Node用（セキュリティ確保） |
| **Security Group** | 最小権限原則 (Least Privilege) | 80/443ポートのみ解放 |

---

### 3. CI/CD パイプライン設計 (Pipeline)

「全冠」を目指すスキルセットとして、自動化プロセスにセキュリティチェックを組み込みます。

#### ステップ詳細:

1. **Checkout:** ソースコードの取得。
2. **Security Scan (App):** `npm audit` によるライブラリ診断。
3. **Build & Scan (Container):**
* `docker build` 実行。
* **Trivy** によるイメージスキャン（`HIGH`, `CRITICAL` 検出時にパイプラインを即停止）。


4. **Push:** 承認されたイメージのみ `ECR` へ。
5. **Deploy:** `Helm upgrade --install` コマンドによるEKSへの反映。

---

### 4. Kubernetes リソース設計 (Manifests/Helm)

マニフェスト管理を柔軟にするため、Helm Chart を使用します。

* **Deployment:** `ReplicaSet` を2以上で設定し、高可用性を確保。
* **Service:** `LoadBalancer` タイプを使用。
* **HPA (Horizontal Pod Autoscaler):** CPU使用率 70% を閾値に自動スケール設定。
* **Resource Quotas:** `requests` と `limits` を明示し、特定Podによるリソース独占を防止。

---

### 5. 運用監視設計 (Monitoring)

「作って終わり」にしない、プロフェッショナルな運用視点です。

* **Prometheus:** EKSクラスター内の全Pod・Nodeのメトリクスを自動収集。
* **Grafana Dashboard:**
* Cluster Overview (Nodeの状態)
* Pod Usage (アプリのリソース消費)
* Network I/O (トラフィック量)
