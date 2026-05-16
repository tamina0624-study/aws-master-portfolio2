ご提示いただいたベース資料に、先ほど精査した「数値の整合性（SSM閉域化、ポート80の直接通信、S3ゲートウェイ等）」をすべて反映・修正した完全版の設計書です。

エンジニアがこのままパラメータシートとして利用できるレベルに整えています。

---

# 🚀 11-DevSecOps-pipeLine 詳細設計書（完全版・修正済）

## 📂 1. ディレクトリ構造とファイル構成

IaC（Terraform）と Kubernetes マニフェスト（Helm）を分離し、ライフサイクルを独立させた構成です。

```text
11-DevSecOps-pipeLine/
├── terraform/                # インフラ構成（EKS/VPC/Endpoints/IAM）
│   ├── main.tf               # Provider, Backend (S3/Local) 設定
│   ├── vpc.tf                # NW基礎 (Subnet, IGW, NATGW, Routes)
│   ├── endpoints.tf          # VPC Endpoints (SSM用閉域網 / Private DNS有効)
│   ├── security_groups.tf    # SG (ALB/Node/Endpoint), NACL定義
│   ├── eks.tf                # EKS Cluster, NodeGroup, AccessEntry
│   ├── iam.tf                # IRSA, NodeRole, Policy, アドオン用権限
│   ├── variables.tf          # 管理者IP等のパラメータ変数
│   └── outputs.tf            # 接続情報出力
├── helm/                     # Kubernetesリソース定義 (Chart化)
│   └── react-app-chart/
│       ├── Chart.yaml        # チャート定義
│       ├── values.yaml       # 環境変数・リソース制限・HPA設定
│       └── templates/        # deployment, service, ingress, hpa 等
├── app/                      # アプリケーション本体
│   ├── src/                  # React ソースコード
│   ├── Dockerfile            # マルチステージビルド (node:20-slim -> nginx:alpine)
│   └── package.json
├── monitoring/               # 監視プラットフォーム設定
│   └── values-prometheus.yaml # 保持期間15日, 30s間隔設定
└── .github/workflows/
    └── pipeline.yml          # GitHub Actions (Trivy Scan, ECR Push, Helm Deploy)

```

---

## 🛠 2. ネットワーク・詳細パラメータ設計 (L3/L4)

### 2.1 VPC / Subnet アドレッシング

| コンポーネント | 項目 | 設定値 | 設計意図・備考 |
| --- | --- | --- | --- |
| **VPC** | CIDRブロック | `10.11.0.0/16` | 既存NWと重複しにくい範囲を選択 |
| **Subnet (Public)** | 11-public-1a/1c | `10.11.1.0/24` / `10.11.2.0/24` | `MapPublicIpOnLaunch: true` (ALB, NATGW用) |
| **Subnet (Private)** | 11-private-1a/1c | `10.11.10.0/24` / `10.11.11.0/24` | `MapPublicIpOnLaunch: false` (EKS Node用) |
| **NAT Gateway** | 配置 | Public Subnet 1a | コスト優先で1台。NodeがECR等へ接続するため |

### 2.2 ルーティング & ゲートウェイ

| コンポーネント | 送信先 | ターゲット | 理由 |
| --- | --- | --- | --- |
| **Internet Gateway** | `0.0.0.0/0` | IGW | パブリック通信の出口 |
| **NAT Gateway** | `0.0.0.0/0` | NATGW | Private Subnetからの標準外部通信用 |
| **S3 Endpoint** | `com.amazonaws.[reg].s3` | **S3 Gateway** | SSM動作の安定化とS3通信の最適化 |

### 2.3 ネットワークACL (NACL)

| 境界 | Inbound 許可 | Outbound 許可 | 理由 |
| --- | --- | --- | --- |
| **Public Subnet** | `80/443`, `1024-65535` | `ANY` | ALBアクセスとエフェメラルポートの確保 |
| **Private Subnet** | `10.11.0.0/16`, `1024-65535` | `ANY` | VPC内通信と応答通信の許可 |

---

## 🛡 3. セキュリティ設計 (Security Group & Multi-layer Defense)

### 3.1 セキュリティグループ (SG)

| 対象 | Inbound 許可 | Outbound 許可 | 備考 |
| --- | --- | --- | --- |
| **ALB用 SG** | `80/443` (from `0.0.0.0/0`) | `ANY` (to Node SG) | インターネットからの入り口 |
| **EKS Node用 SG** | **`80`** (from ALB SG) | `ANY` | **Target-Type: IP** によるPodへの直接通信 |
| **EKS Node用 SG** | `10250` (from Cluster SG) | - | Kubelet API |
| **Endpoint用 SG** | `443` (from Node SG) | - | SSM用閉域アクセス（SSMのみに限定） |

### 3.2 SSM プライベートアクセス (VPC Endpoint)

SSM Agentの通信をNATGWを通さず、AWS内部ネットワークで完結させます。

* **作成エンドポイント (Interface型):**
* `com.amazonaws.[region].ssm`
* `com.amazonaws.[region].ssmmessages`
* `com.amazonaws.[region].ec2messages`
* **重要設定:** `Private DNS Enabled: True`


* **通信フロー:** Node → VPC Endpoint (Private IP) → AWS SSM Service

---

## 🏗 4. EKS クラスター & アプリケーション実行基盤

### 4.1 EKS パラメータ

| 項目 | 設定値 | 設計意図 |
| --- | --- | --- |
| **K8s Version** | `1.29` | 安定版。Managed Node Group でパッチ管理 |
| **Instance Type** | `t3.medium` | 2 vCPU / 4GiB RAM。最小構成の冗長化 |
| **Scaling Config** | Desired: 2, Min: 2, Max: 4 | AZ冗長性とオートスケーリングの確保 |
| **Disk Size** | `20 GB` (gp3) | スループット重視のストレージ選定 |

### 4.2 アドオン & コントローラー

| アドオン名 | 役割 | 備考 |
| --- | --- | --- |
| **AWS LB Controller** | IngressからALBを自動生成 | **Target-Type: ip** モードを使用 |
| **CoreDNS** | クラスター内部の名前解決 | Pod間通信の基礎 |
| **VPC CNI** | PodにVPCのIPを直接付与 | 高速な通信パフォーマンス |

---

## 🔑 5. 権限・管理アクセス設計 (IAM & RBAC)

### 5.1 IAM 役割 (Roles) とポリシー

1. **ALB Controller 用 (IRSA):** ALB操作に必要な権限をPodに付与。
2. **EKS Node 用:**
* `AmazonEKSWorkerNodePolicy`: 必須
* `AmazonEKS_CNI_Policy`: ネットワーク用
* `AmazonEC2ContainerRegistryReadOnly`: ECRイメージ取得用
* `AmazonSSMManagedInstanceCore`: **SSMログイン用（必須）**


3. **Reactアプリ (Pod) 用:** 基本 `なし`。

### 5.2 管理操作アクセス

* **EKS API:** `Public and Private Access` 有効。Publicは管理者IPのみに制限。
* **EKS Access Entry:** あなたの IAM ユーザーを `system:masters` に紐付け。
* **Node Access:** SSHポート(22)は利用せず、**SSM Session Manager** 経由のログインに限定。

---

## 🚀 6. DevSecOps & 可観測性 (Observability)

### 6.1 パイプライン (GitHub Actions) / Kubernetes

* **Trivy スキャン:** `severity: HIGH,CRITICAL`, `exit-code: 1` で脆弱性検知時にデプロイ停止。
* **ECR 設定:** `Scan on push: true`, 直近5イメージ保持のライフサイクル。
* **K8s Manifest:**
* `Replicas: 2`, `RollingUpdate` 戦略（maxSurge 25%）。
* `Resource Limit`: `cpu: 500m`, `memory: 256Mi` (OOM防止)。
* `Health Check`: `Liveness/Readiness Probe` を **`/` (ポート80)** に設定。



### 6.2 監視 (Prometheus / Grafana)

* **データ保持:** 15日間。
* **スクレイプ間隔:** 30秒。
* **監視対象:** Node(CPU/RAM), Pod(Status/Network I/O)。

---

## 💡 7. 設計のポイント（面接対策用）

1. **管理通信の完全分離:** SSM通信のみをVPC Endpointで閉域化。NATゲートウェイの負荷を下げつつ、セキュアな管理経路を構築。
2. **多層防御の実装:** ネットワーク(NACL)・インスタンス(SG)・権限(IAM)・アクセス制限(IP制限)の4段階で防御。
3. **実務的自動化:** TerraformによるIaC、HelmによるK8s管理、GitHub ActionsによるSecOpsを統合したモダンな構成。
