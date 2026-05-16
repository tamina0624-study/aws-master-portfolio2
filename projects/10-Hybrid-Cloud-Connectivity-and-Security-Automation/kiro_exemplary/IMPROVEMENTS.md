# 改善点サマリー（元コードとの差分）

## 1. セキュリティルール準拠

| 項目 | 元コード | Kiro版 |
|------|----------|--------|
| リソース名プレフィックス | `prod-hcsa-*` | `xxxx-x-*`（ルール準拠） |
| リージョン | `us-east-2` | `us-east-1`（ルール準拠） |
| クレデンシャル管理 | ファイル読み込み / ハードコード | SSM Parameter Store |
| SG: All Traffic | `protocol = "-1"` で全許可あり | プロトコル・ポート明示 |
| SG: 0.0.0.0/0 port 22 | 一部存在 | 許可IPリストのみ or SSM推奨 |
| IAM: RDS権限 | `AmazonRDSFullAccess` | `rds-db:connect` のみ（最小権限） |
| Lambda Runtime | `python3.8`（EOL） | `python3.12` |
| タグ `xxxx-x` | なし | 全リソースに付与 |

## 2. コード品質

| 項目 | 元コード | Kiro版 |
|------|----------|--------|
| ファイル分割 | 1つの巨大 `main.tf` | 機能別に分割（vpn.tf, iam.tf, etc.） |
| インデント | 混在（タブ/スペース） | 統一（2スペース） |
| コメント | 少ない | セクションヘッダー + 説明付き |
| 変数命名 | 一部不統一 | 一貫した命名規則 |
| locals活用 | なし | 共通値をlocalsで一元管理 |
| lifecycle | なし | deny-ipsetに `ignore_changes` 設定 |

## 3. アーキテクチャ改善

| 項目 | 元コード | Kiro版 |
|------|----------|--------|
| GuardDuty Detector | リソース定義なし | 明示的に作成 |
| Lambda環境変数 | ハードコード前提 | Terraform outputから自動設定 |
| EventBridge pattern | 文字列ベース | `jsonencode` + prefix match |
| AppServer起動 | `nohup` バックグラウンド | systemdサービス化 |
| RDSパスワード | ローカルファイル参照 | SSM Parameter Store |
| WAF deny-ipset | Terraform管理 | `ignore_changes` でLambda更新を保護 |

## 4. 運用性

| 項目 | 元コード | Kiro版 |
|------|----------|--------|
| tfvars例 | なし | `terraform.tfvars.example` 提供 |
| README | 簡素 | アーキテクチャ図 + デプロイ手順 |
| Output | 基本的 | 運用に必要な情報を網羅 |
| Secret管理 | gitリポジトリ内にファイル | SSM（リポジトリ外） |

## 5. 残課題（本exemplaryでは未実装）

- WAF WebACLの作成とALBへのアタッチ
- CloudWatch Alarmの設定
- バックアップ・リストア設計
- マルチAZ冗長化
- CI/CDパイプライン
- tfstateのリモートバックエンド（S3 + DynamoDB）
