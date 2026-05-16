# Tasks: ハイブリッド・クラウド接続とセキュリティ自動化

## 実装タスク一覧

各タスクは要件(requirements.md)と設計(design.md)に基づいて定義されています。

---

### Task 1: プロジェクト基盤の構築

**対応要件**: NFR-002, NFR-005

**説明**: Terraformプロジェクトの基盤ファイルを作成する。プロバイダ設定、共通変数、ローカル値、データソースを定義する。

**実装ファイル**:
- `provider.tf` - AWSプロバイダ設定（us-east-1固定）
- `locals.tf` - プレフィックス、共通タグ、許可IPリスト
- `variables.tf` - 全入力変数の定義
- `data.tf` - AMI、SSM Parameter Storeデータソース
- `terraform.tfvars.example` - 変数値サンプル

**完了条件**:
- [x] `terraform init` が成功する
- [x] `terraform validate` が成功する
- [x] 全変数にdescriptionとtype定義がある
- [x] リージョンが `us-east-1` に設定されている

---

### Task 2: VPCとネットワーク基盤の構築

**対応要件**: FR-001, NFR-003

**説明**: AWS側VPCと疑似オンプレVPCを作成し、サブネット・ルートテーブル・インターネットゲートウェイを構成する。

**実装ファイル**:
- `modules/vpc/main.tf` - VPCモジュール
- `modules/vpc/variables.tf` - モジュール変数
- `modules/vpc/outputs.tf` - モジュール出力
- `main.tf` - VPCモジュール呼び出し、ルートテーブル、IGW

**完了条件**:
- [x] prod-vpc (10.0.0.0/16) が作成される
- [x] onprem-vpc (10.1.0.0/16) が作成される
- [x] 各VPCにパブリック/プライベートサブネットが2つずつ作成される
- [x] ルートテーブルが正しく関連付けられる
- [x] 全リソースに `xxxx-x` プレフィックスとタグが付与される

---

### Task 3: VPN接続の構築

**対応要件**: FR-001

**説明**: Site-to-Site VPN接続を構築する。VGW、CGW、VPN Connection、EIPを作成し、BGPルーティングを設定する。

**実装ファイル**:
- `vpn.tf` - VPN関連リソース全体

**完了条件**:
- [x] VPN Gateway がprod-vpcにアタッチされる
- [x] Customer Gateway がオンプレルーターのEIPを参照する
- [x] VPN接続が2トンネル構成で作成される
- [x] BGPルート伝播がプライベートサブネットに設定される

---

### Task 4: セキュリティグループの構築

**対応要件**: FR-005, NFR-001

**説明**: 最小権限に基づくセキュリティグループを作成する。All Traffic禁止、0.0.0.0/0 port22禁止のルールに準拠する。

**実装ファイル**:
- `security_groups.tf` - 全セキュリティグループ定義

**完了条件**:
- [x] prod-app-sg: 内部通信 + 許可IPからのHTTP/HTTPS のみ
- [x] prod-rds-sg: AppServer SGからの3306のみ
- [x] onprem-sg: 内部通信 + VPNポート + 許可IPからのSSH
- [x] All Traffic / All Protocol のルールが存在しない
- [x] 0.0.0.0/0 port 22 のルールが存在しない

---

### Task 5: ネットワークACLの構築

**対応要件**: FR-005

**説明**: サブネット単位のネットワークACLを作成する。基本Allow + 最終Denyのシンプルな構成とする。

**実装ファイル**:
- `network_acl.tf` - ネットワークACL定義

**完了条件**:
- [x] prod-acl: VPC内通信許可、エフェメラルポート許可、最終Deny
- [x] onprem-acl: VPC内通信許可、VPNポート許可、最終Deny
- [x] 全サブネットにACLが関連付けられる

---

### Task 6: IAMロール・ポリシーの構築

**対応要件**: NFR-001

**説明**: EC2およびLambda用のIAMロールを最小権限で作成する。

**実装ファイル**:
- `iam.tf` - 全IAMリソース定義

**完了条件**:
- [x] AppServer: SSM + CloudWatch + rds-db:connect のみ
- [x] RouterPC/UserPC: SSM + CloudWatch のみ
- [x] Lambda: CloudWatch Logs + WAF IPSet更新 + SG/ACL操作
- [x] AdministratorAccess が使用されていない
- [x] AmazonRDSFullAccess が使用されていない
- [x] Lambda用WAF権限が対象IPSetのARNに限定されている

---

### Task 7: EC2インスタンスの構築

**対応要件**: FR-002

**説明**: AppServer、RouterPC、UserPCの3台のEC2インスタンスを作成する。

**実装ファイル**:
- `modules/ec2/main.tf` - EC2モジュール
- `modules/ec2/variables.tf` - モジュール変数
- `modules/ec2/outputs.tf` - モジュール出力
- `modules/ec2/appserver_userdata.sh.tpl` - AppServer初期化スクリプト
- `modules/ec2/vpn_setup.sh.tpl` - VPNルーター初期化スクリプト
- `ec2.tf` - EC2モジュール呼び出し

**完了条件**:
- [x] AppServer: AL2023, t2.micro, Flask + systemd
- [x] RouterPC: Ubuntu 24.04, strongSwan + FRR自動構築
- [x] UserPC: AL2023, t2.micro
- [x] 全EC2にIAMインスタンスプロファイルが付与される
- [x] RouterPCの source_dest_check が false

---

### Task 8: RDSの構築

**対応要件**: FR-003, NFR-001

**説明**: MySQL RDSインスタンスをプライベートサブネットに作成する。

**実装ファイル**:
- `rds.tf` - RDS関連リソース

**完了条件**:
- [x] プライベートサブネットに配置される
- [x] publicly_accessible = false
- [x] IAM認証が有効
- [x] パスワードがSSM Parameter Storeから取得される
- [x] AppServer SGからのみ3306アクセス可能

---

### Task 9: WAF IPSetの構築

**対応要件**: FR-005

**説明**: WAF v2のallow-ipsetとdeny-ipsetを作成する。

**実装ファイル**:
- `waf.tf` - WAF IPSet定義

**完了条件**:
- [x] allow-ipset: 内部CIDRが登録される
- [x] deny-ipset: 初期はダミーアドレスのみ
- [x] deny-ipsetに `lifecycle.ignore_changes` が設定される

---

### Task 10: GuardDuty + 自動防御の構築

**対応要件**: FR-004

**説明**: GuardDuty、EventBridge、Lambda関数を連携させ、脅威検知→自動遮断の仕組みを構築する。

**実装ファイル**:
- `guardduty.tf` - GuardDuty + EventBridge + Lambda
- `modules/lambda/lambda_function.py` - Lambda関数コード

**完了条件**:
- [x] GuardDuty Detectorが有効化される
- [x] EventBridgeルールが9種類の脅威タイプをフィルタする
- [x] LambdaがEventBridgeから呼び出される
- [x] Lambda環境変数にIPSet ID/Name/Scopeが設定される
- [x] Lambdaが攻撃元IPをdeny-ipsetに追加する

---

### Task 11: 出力値の定義

**対応要件**: NFR-005

**説明**: 運用に必要な情報をTerraform outputとして定義する。

**実装ファイル**:
- `outputs.tf` - 全出力値

**完了条件**:
- [x] VPC ID、サブネットID
- [x] EC2インスタンスID
- [x] RDSエンドポイント
- [x] VPN接続ID、トンネルアドレス
- [x] GuardDuty Detector ID
- [x] deny-ipset ID

---

## タスク依存関係

```
Task 1 (基盤)
  ├── Task 2 (VPC)
  │     ├── Task 3 (VPN)
  │     ├── Task 4 (SG)
  │     │     ├── Task 7 (EC2)
  │     │     └── Task 8 (RDS)
  │     └── Task 5 (ACL)
  ├── Task 6 (IAM)
  │     ├── Task 7 (EC2)
  │     └── Task 10 (GuardDuty)
  └── Task 9 (WAF)
        └── Task 10 (GuardDuty)

Task 11 (出力) ← 全タスク完了後
```

## 進捗サマリー

| タスク | ステータス | 備考 |
|--------|-----------|------|
| Task 1: プロジェクト基盤 | ✅ 完了 | |
| Task 2: VPC・ネットワーク | ✅ 完了 | |
| Task 3: VPN接続 | ✅ 完了 | |
| Task 4: セキュリティグループ | ✅ 完了 | |
| Task 5: ネットワークACL | ✅ 完了 | |
| Task 6: IAMロール | ✅ 完了 | |
| Task 7: EC2インスタンス | ✅ 完了 | |
| Task 8: RDS | ✅ 完了 | |
| Task 9: WAF IPSet | ✅ 完了 | |
| Task 10: GuardDuty自動防御 | ✅ 完了 | |
| Task 11: 出力値 | ✅ 完了 | |
