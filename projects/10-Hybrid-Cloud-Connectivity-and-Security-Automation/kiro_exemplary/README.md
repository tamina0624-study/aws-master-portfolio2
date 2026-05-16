# ハイブリッド・クラウド接続とセキュリティ自動化 (Kiro Exemplary)

## 概要

本構成は、オンプレミス環境（疑似VPC）とAWS VPCをSite-to-Site VPNで接続し、
GuardDuty + EventBridge + Lambda による自律防御を実現するTerraformプロジェクトです。

## アーキテクチャ

```
┌─────────────────────────────────────────────────────────────────────┐
│                         AWS Cloud (us-east-1)                        │
│                                                                      │
│  ┌──────────────────────────┐     ┌──────────────────────────────┐  │
│  │  onprem-vpc (10.1.0.0/16)│     │  prod-vpc (10.0.0.0/16)      │  │
│  │                          │     │                               │  │
│  │  ┌────────┐ ┌────────┐  │ VPN │  ┌────────┐   ┌──────────┐  │  │
│  │  │RouterPC│ │ UserPC │  │◄───►│  │AppServer│   │   RDS    │  │  │
│  │  │(Ubuntu)│ │(AL2023)│  │     │  │ (AL2023)│   │ (MySQL)  │  │  │
│  │  └────────┘ └────────┘  │     │  └────────┘   └──────────┘  │  │
│  │                          │     │                               │  │
│  └──────────────────────────┘     └──────────────────────────────┘  │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │  Security Layer                                               │   │
│  │  • GuardDuty → EventBridge → Lambda → WAF deny-ipset更新    │   │
│  │  • WAF (ALB前段) + IPSet制御                                  │   │
│  │  • Network ACL + Security Group (最小権限)                    │   │
│  └──────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

## ディレクトリ構成

```
kiro_exemplary/
├── README.md                    # 本ファイル
├── main.tf                      # ルートモジュール（リソース定義）
├── variables.tf                 # 変数定義
├── outputs.tf                   # 出力定義
├── provider.tf                  # プロバイダ設定
├── locals.tf                    # ローカル変数
├── data.tf                      # データソース
├── terraform.tfvars.example     # 変数値のサンプル
└── modules/
    ├── vpc/                     # VPC・サブネット
    ├── ec2/                     # EC2インスタンス
    └── lambda/                  # Lambda関数（自動防御）
```

## セキュリティ方針

- 全リソース名の先頭に `xxxx-x` プレフィックスを付与
- クレデンシャルはSSM Parameter Storeで管理（ハードコード禁止）
- セキュリティグループは最小権限（All Traffic / All Protocol 禁止）
- `0.0.0.0/0` port 22 は禁止（SSM Session Manager経由で管理）
- RDSはプライベートサブネット配置、パブリックアクセス無効
- Web UIは許可IPリストからのみアクセス可能
- GuardDuty検知 → Lambda自動遮断の仕組みを実装

## デプロイ手順

```bash
# 1. 変数ファイルを準備
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars を環境に合わせて編集

# 2. 初期化
terraform init

# 3. プラン確認
terraform plan

# 4. デプロイ
terraform apply
```

## 注意事項

- デプロイリージョンは `us-east-1` のみ
- 既存AWSリソースとの競合に注意
- RDSのマスターパスワードはSSM Parameter Storeに事前登録が必要
