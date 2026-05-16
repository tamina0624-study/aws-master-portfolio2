# AWS & Kubernetes Master Portfolio

このプロジェクトは、AWS上にTerraformを用いて堅牢なインフラを構築し、
Kubernetesを利用してスケーラブルなNginxサーバーを運用するポートフォリオです。

## 🏗 システム構成図
graph TD
    User --> Service[Kubernetes Service]
    Service --> Pod1[Nginx Pod 1]
    Service --> Pod2[Nginx Pod 2]
    Service --> Pod3[Nginx Pod 3]
    subgraph AWS Cloud
    Pod1
    Pod2
    Pod3
    end

## 🛠 使用技術
- **Infrastructure as Code:** Terraform
- **Cloud:** AWS (VPC, EC2, Security Group)
- **Orchestration:** Kubernetes (Deployment, Service, ConfigMap)
- **Web Server:** Nginx

## 🚀 主な機能と実装内容

### 1. TerraformによるIaC（インフラの自動化）
- **VPC / Subnet 設計:** 拡張性を考慮したネットワーク構成の構築。
- **セキュリティの自動化:** `http`データソースを活用し、作業者のグローバルIPアドレスを自動取得してSSH接続を制限するセキュリティグループの実装。
- **モジュール化:** コンピュートリソースの再利用性を高めるためのモジュール分割。

### 2. Kubernetesによるコンテナ運用
- **宣言的管理:** `kubectl apply` コマンドを用いたリソースの一元管理。
- **自己修復機能:** DeploymentによるPodのレプリカ維持と自動復旧。
- **サービス公開:** Serviceを用いた負荷分散と固定アクセスポイントの提供。
- **設定の分離:** ConfigMapによる環境設定とアプリケーション本体の分離。

## 📂 ディレクトリ構造
.
├── 01-basic-infrastructure/  # AWSインフラ（Terraform）
│   ├── terraform/
│   │   ├── main.tf           # メイン構成
│   │   ├── modules/          # 各リソースのモジュール
│   │   └── variables.tf      # 変数定義
└── manifests/                # Kubernetesマニフェスト
    ├── nginx-deployment.yaml # デプロイ設定
    ├── nginx-service.yaml    # サービス設定
    └── nginx-config.yaml     # 設定ファイル
