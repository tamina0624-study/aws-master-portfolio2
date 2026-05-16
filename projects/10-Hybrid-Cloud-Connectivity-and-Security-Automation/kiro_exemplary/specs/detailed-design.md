# 詳細設計書: ハイブリッド・クラウド接続とセキュリティ自動化

## 1. ネットワーク詳細設計

### 1.1 VPC・サブネット定義

#### AWS側VPC (prod)

| リソース | 名前 | CIDR / 設定 | AZ |
|---------|------|-------------|-----|
| VPC | xxxx-x-prod-hcsa-vpc | 10.0.0.0/16 | - |
| パブリックサブネット1 | xxxx-x-prod-hcsa-vpc-public-1 | 10.0.1.0/24 | us-east-1a |
| パブリックサブネット2 | xxxx-x-prod-hcsa-vpc-public-2 | 10.0.2.0/24 | us-east-1b |
| プライベートサブネット1 | xxxx-x-prod-hcsa-vpc-private-1 | 10.0.11.0/24 | us-east-1a |
| プライベートサブネット2 | xxxx-x-prod-hcsa-vpc-private-2 | 10.0.12.0/24 | us-east-1b |
| Internet Gateway | xxxx-x-prod-hcsa-igw | - | - |
| VPN Gateway | xxxx-x-prod-hcsa-vgw | ASN: 65000 | - |

#### 疑似オンプレVPC

| リソース | 名前 | CIDR / 設定 | AZ |
|---------|------|-------------|-----|
| VPC | xxxx-x-onprem-hcsa-vpc | 10.1.0.0/16 | - |
| パブリックサブネット1 | xxxx-x-onprem-hcsa-vpc-public-1 | 10.1.1.0/24 | us-east-1a |
| パブリックサブネット2 | xxxx-x-onprem-hcsa-vpc-public-2 | 10.1.2.0/24 | us-east-1b |
| プライベートサブネット1 | xxxx-x-onprem-hcsa-vpc-private-1 | 10.1.3.0/24 | us-east-1a |
| プライベートサブネット2 | xxxx-x-onprem-hcsa-vpc-private-2 | 10.1.4.0/24 | us-east-1b |
| Internet Gateway | xxxx-x-onprem-hcsa-igw | - | - |
| Customer Gateway | xxxx-x-onprem-cgw | ASN: 65001 | - |

### 1.2 ルートテーブル定義

#### prod-public-rtb (AWS側パブリック)

| 宛先 | ターゲット | 備考 |
|------|-----------|------|
| 10.0.0.0/16 | local | VPC内通信 |
| 0.0.0.0/0 | xxxx-x-prod-hcsa-igw | インターネット |

#### prod-private-rtb (AWS側プライベート)

| 宛先 | ターゲット | 備考 |
|------|-----------|------|
| 10.0.0.0/16 | local | VPC内通信 |
| 10.1.0.0/16 | VGW (BGP伝播) | オンプレ宛VPN経由 |

#### onprem-rtb (オンプレ側)

| 宛先 | ターゲット | 備考 |
|------|-----------|------|
| 10.1.0.0/16 | local | VPC内通信 |
| 0.0.0.0/0 | xxxx-x-onprem-hcsa-igw | インターネット |
| 10.0.0.0/16 | RouterPC (VPN経由) | AWS宛VPN経由 |

### 1.3 VPN接続定義

| 項目 | 値 |
|------|-----|
| 接続タイプ | ipsec.1 |
| ルーティング | BGP (動的) |
| static_routes_only | false |
| AWS側ASN | 65000 |
| オンプレ側ASN | 65001 |
| トンネル数 | 2 (冗長) |
| CGW IPアドレス | RouterPC の Elastic IP |

#### トンネル設定

| 項目 | Tunnel 1 | Tunnel 2 |
|------|----------|----------|
| 外部IP | AWS自動割当 | AWS自動割当 |
| 内部CIDR | AWS自動割当 (/30) | AWS自動割当 (/30) |
| PSK | AWS自動生成 | AWS自動生成 |
| VTI mark | 10 | 11 |

---

## 2. コンピュート詳細設計

### 2.1 EC2インスタンス定義

#### AppServer (アプリケーションサーバー)

| 項目 | 値 |
|------|-----|
| Name | xxxx-x-hcsa-appserver-prod-01 |
| AMI | Amazon Linux 2023 (最新) |
| インスタンスタイプ | t2.micro |
| VPC | xxxx-x-prod-hcsa-vpc |
| サブネット | public-1 (10.0.1.0/24, us-east-1a) |
| セキュリティグループ | xxxx-x-prod-hcsa-app-sg |
| パブリックIP | あり |
| IAMロール | xxxx-x-hcsa-ec2-appserver-role |
| キーペア | id_rsa_aws |
| source_dest_check | false |
| user_data | appserver_userdata.sh.tpl |

#### RouterPC (VPNルーター)

| 項目 | 値 |
|------|-----|
| Name | xxxx-x-hcsa-routerpc-dev-01 |
| AMI | Ubuntu 24.04 LTS |
| インスタンスタイプ | t2.micro |
| VPC | xxxx-x-onprem-hcsa-vpc |
| サブネット | public-1 (10.1.1.0/24, us-east-1a) |
| セキュリティグループ | xxxx-x-onprem-hcsa-sg |
| パブリックIP | Elastic IP |
| IAMロール | xxxx-x-hcsa-ec2-routerpc-role |
| キーペア | id_rsa_aws |
| source_dest_check | false |
| user_data | vpn_setup.sh.tpl |

#### UserPC (ユーザー操作端末)

| 項目 | 値 |
|------|-----|
| Name | xxxx-x-hcsa-userpc-dev-01 |
| AMI | Amazon Linux 2023 (最新) |
| インスタンスタイプ | t2.micro |
| VPC | xxxx-x-onprem-hcsa-vpc |
| サブネット | public-1 (10.1.1.0/24, us-east-1a) |
| セキュリティグループ | xxxx-x-onprem-hcsa-sg |
| パブリックIP | あり |
| IAMロール | xxxx-x-hcsa-ec2-userpc-role |
| キーペア | id_rsa_aws |
| source_dest_check | false |
| user_data | なし |

### 2.2 AppServer アプリケーション構成

```
/opt/app.py          - Flask Webアプリケーション
/etc/systemd/system/flask-app.service - systemdサービス定義
```

#### エンドポイント一覧

| パス | メソッド | 機能 |
|------|---------|------|
| / | GET | トップページ（稼働確認） |
| /health | GET | ヘルスチェック |
| /db/status | GET | DB接続確認 |
| /users | GET | ユーザー一覧取得 |

### 2.3 RouterPC ソフトウェア構成

| ソフトウェア | バージョン | 用途 |
|-------------|-----------|------|
| strongSwan (swanctl) | OS標準 | IPsec VPN |
| FRR | OS標準 | BGPルーティング |

#### VTIインターフェース

| インターフェース | ローカルIP | リモートIP | mark |
|----------------|-----------|-----------|------|
| vti-t1 | RouterPC private IP | Tunnel1外部IP | 10 |
| vti-t2 | RouterPC private IP | Tunnel2外部IP | 11 |

---

## 3. データベース詳細設計

### 3.1 RDSインスタンス定義

| 項目 | 値 |
|------|-----|
| 識別子 | xxxx-x-prod-hcsa-rds |
| エンジン | MySQL 8.0 |
| インスタンスクラス | db.t4g.micro |
| ストレージ | gp2, 20GB |
| VPC | xxxx-x-prod-hcsa-vpc |
| サブネットグループ | private-1, private-2 |
| AZ | us-east-1a |
| セキュリティグループ | xxxx-x-prod-hcsa-rds-sg |
| パブリックアクセス | false |
| Multi-AZ | false |
| IAM認証 | 有効 |
| 削除保護 | false（開発環境） |
| 最終スナップショット | スキップ |
| マスターユーザー | admin |
| パスワード管理 | SSM Parameter Store (`/hcsa/rds/master_password`) |

### 3.2 スキーマ定義

```sql
-- データベース
CREATE DATABASE hcsa_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ユーザーテーブル
CREATE TABLE hcsa_db.users (
  id         INT          PRIMARY KEY AUTO_INCREMENT,
  name       VARCHAR(255) NOT NULL,
  email      VARCHAR(255) NOT NULL UNIQUE,
  password   VARCHAR(255) NOT NULL,
  created_at DATETIME     DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

---

## 4. セキュリティ詳細設計

### 4.1 セキュリティグループ定義

#### xxxx-x-prod-hcsa-app-sg (AppServer用)

**Inbound:**

| ルール# | ポート | プロトコル | 送信元 | 用途 |
|---------|--------|-----------|--------|------|
| 1 | 0-65535 | TCP | 10.0.1.0/24, 10.0.2.0/24, 10.0.11.0/24, 10.0.12.0/24, 10.1.1.0/24, 10.1.2.0/24, 10.1.3.0/24, 10.1.4.0/24 | 内部通信 |
| 2 | ICMP | ICMP | 同上 | 疎通確認 |
| 3 | 80 | TCP | 許可IPリスト (24件) | Web UI |
| 4 | 443 | TCP | 許可IPリスト (24件) | HTTPS |

**Outbound:**

| ルール# | ポート | プロトコル | 送信先 | 用途 |
|---------|--------|-----------|--------|------|
| 1 | ALL | ALL | 0.0.0.0/0 | 全外部通信 |

#### xxxx-x-prod-hcsa-rds-sg (RDS用)

**Inbound:**

| ルール# | ポート | プロトコル | 送信元 | 用途 |
|---------|--------|-----------|--------|------|
| 1 | 3306 | TCP | xxxx-x-prod-hcsa-app-sg | MySQL |

**Outbound:**

| ルール# | ポート | プロトコル | 送信先 | 用途 |
|---------|--------|-----------|--------|------|
| 1 | ALL | ALL | 0.0.0.0/0 | 全外部通信 |

#### xxxx-x-onprem-hcsa-sg (オンプレVPC用)

**Inbound:**

| ルール# | ポート | プロトコル | 送信元 | 用途 |
|---------|--------|-----------|--------|------|
| 1 | 0-65535 | TCP | 内部CIDR (8件) | 内部通信 |
| 2 | ICMP | ICMP | 内部CIDR (8件) | 疎通確認 |
| 3 | 500 | UDP | VPNトンネル1,2 外部IP | IKE |
| 4 | 4500 | UDP | VPNトンネル1,2 外部IP | NAT-T |
| 5 | 22 | TCP | 許可IPリスト (24件) | SSH管理 |

**Outbound:**

| ルール# | ポート | プロトコル | 送信先 | 用途 |
|---------|--------|-----------|--------|------|
| 1 | ALL | ALL | 0.0.0.0/0 | 全外部通信 |

### 4.2 ネットワークACL定義

#### xxxx-x-prod-hcsa-acl

**Inbound:**

| ルール# | プロトコル | ポート | 送信元 | アクション | 用途 |
|---------|-----------|--------|--------|-----------|------|
| 10 | ICMP | ALL | 0.0.0.0/0 | ALLOW | ping |
| 20 | ALL | ALL | 10.0.0.0/16 | ALLOW | VPC内 |
| 30 | ALL | ALL | 10.1.0.0/16 | ALLOW | オンプレから |
| 100 | TCP | 1024-65535 | 0.0.0.0/0 | ALLOW | エフェメラル |
| 110 | TCP | 80 | 0.0.0.0/0 | ALLOW | HTTP |
| 120 | TCP | 443 | 0.0.0.0/0 | ALLOW | HTTPS |
| 32766 | ALL | ALL | 0.0.0.0/0 | DENY | 最終拒否 |

**Outbound:**

| ルール# | プロトコル | ポート | 送信先 | アクション |
|---------|-----------|--------|--------|-----------|
| 100 | ALL | ALL | 0.0.0.0/0 | ALLOW |

#### xxxx-x-onprem-hcsa-acl

**Inbound:**

| ルール# | プロトコル | ポート | 送信元 | アクション | 用途 |
|---------|-----------|--------|--------|-----------|------|
| 10 | ICMP | ALL | 0.0.0.0/0 | ALLOW | ping |
| 20 | ALL | ALL | 10.1.0.0/16 | ALLOW | VPC内 |
| 30 | ALL | ALL | 10.0.0.0/16 | ALLOW | AWSから |
| 40 | UDP | 500 | 0.0.0.0/0 | ALLOW | IKE |
| 41 | UDP | 4500 | 0.0.0.0/0 | ALLOW | NAT-T |
| 100 | TCP | 1024-65535 | 0.0.0.0/0 | ALLOW | エフェメラル |
| 110 | TCP | 22 | 0.0.0.0/0 | ALLOW | SSH |
| 32766 | ALL | ALL | 0.0.0.0/0 | DENY | 最終拒否 |

**Outbound:**

| ルール# | プロトコル | ポート | 送信先 | アクション |
|---------|-----------|--------|--------|-----------|
| 100 | ALL | ALL | 0.0.0.0/0 | ALLOW |

### 4.3 WAF IPSet定義

#### xxxx-x-allow-ipset

| 項目 | 値 |
|------|-----|
| スコープ | REGIONAL |
| IPバージョン | IPv4 |
| 登録アドレス | 10.0.1.0/24, 10.0.2.0/24, 10.0.11.0/24, 10.0.12.0/24, 10.1.1.0/24, 10.1.2.0/24, 10.1.3.0/24, 10.1.4.0/24 |

#### xxxx-x-deny-ipset

| 項目 | 値 |
|------|-----|
| スコープ | REGIONAL |
| IPバージョン | IPv4 |
| 初期アドレス | 255.255.255.255/32 (ダミー) |
| lifecycle | ignore_changes = [addresses] |
| 更新方法 | Lambda関数による動的追加 |

---

## 5. IAM詳細設計

### 5.1 EC2ロール定義

#### xxxx-x-hcsa-ec2-appserver-role

| ポリシー | ARN / 内容 | 用途 |
|---------|------------|------|
| AmazonSSMManagedInstanceCore | AWS管理ポリシー | SSM Session Manager |
| CloudWatchAgentServerPolicy | AWS管理ポリシー | ログ・メトリクス送信 |
| xxxx-x-hcsa-appserver-rds-connect | カスタム: `rds-db:connect` | RDS IAM認証接続 |

#### xxxx-x-hcsa-ec2-routerpc-role

| ポリシー | ARN / 内容 | 用途 |
|---------|------------|------|
| AmazonSSMManagedInstanceCore | AWS管理ポリシー | SSM Session Manager |
| CloudWatchAgentServerPolicy | AWS管理ポリシー | ログ・メトリクス送信 |

#### xxxx-x-hcsa-ec2-userpc-role

| ポリシー | ARN / 内容 | 用途 |
|---------|------------|------|
| AmazonSSMManagedInstanceCore | AWS管理ポリシー | SSM Session Manager |
| CloudWatchAgentServerPolicy | AWS管理ポリシー | ログ・メトリクス送信 |

### 5.2 Lambda ロール定義

#### xxxx-x-hcsa-lambda-block-attacker-role

| ポリシー | 内容 | 用途 |
|---------|------|------|
| AWSLambdaBasicExecutionRole | AWS管理ポリシー | CloudWatch Logs書き込み |
| xxxx-x-hcsa-lambda-security-actions | カスタム（下記） | セキュリティ操作 |

**カスタムポリシー詳細:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["wafv2:GetIPSet", "wafv2:UpdateIPSet"],
      "Resource": "arn:aws:wafv2:us-east-1:*:regional/ipset/xxxx-x-deny-ipset/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:DescribeSecurityGroups"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkAclEntry",
        "ec2:DeleteNetworkAclEntry",
        "ec2:ReplaceNetworkAclEntry",
        "ec2:DescribeNetworkAcls"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## 6. セキュリティ自動防御 詳細設計

### 6.1 GuardDuty設定

| 項目 | 値 |
|------|-----|
| Detector | 有効 |
| リージョン | us-east-1 |
| Finding頻度 | デフォルト（15分） |

### 6.2 EventBridgeルール定義

| 項目 | 値 |
|------|-----|
| ルール名 | xxxx-x-hcsa-guardduty-to-lambda |
| イベントバス | default |
| ソース | aws.guardduty |
| detail-type | GuardDuty Finding |
| ターゲット | xxxx-x-hcsa-block-attacker (Lambda) |

**フィルタパターン:**

```json
{
  "source": ["aws.guardduty"],
  "detail-type": ["GuardDuty Finding"],
  "detail": {
    "type": [
      {"prefix": "UnauthorizedAccess"},
      {"prefix": "Recon"},
      {"prefix": "Trojan"},
      {"prefix": "Backdoor"},
      {"prefix": "CryptoCurrency"},
      {"prefix": "Impact"},
      {"prefix": "Persistence"},
      {"prefix": "PenTest"},
      {"prefix": "Behavior"}
    ]
  }
}
```

### 6.3 Lambda関数定義

| 項目 | 値 |
|------|-----|
| 関数名 | xxxx-x-hcsa-block-attacker |
| ランタイム | Python 3.12 |
| ハンドラー | lambda_function.lambda_handler |
| メモリ | 128 MB |
| タイムアウト | 10秒 |
| トリガー | EventBridge |
| 実行ロール | xxxx-x-hcsa-lambda-block-attacker-role |

**環境変数:**

| キー | 値 | 説明 |
|------|-----|------|
| WAFV2_IP_SET_ID | (Terraform output) | deny-ipsetのID |
| WAFV2_IP_SET_NAME | xxxx-x-deny-ipset | deny-ipsetの名前 |
| WAFV2_SCOPE | REGIONAL | WAFスコープ |

**処理フロー:**

```
1. EventBridgeからGuardDuty Findingイベントを受信
2. イベントから攻撃元IPを抽出
   - portProbeAction.portProbeDetails[].remoteIpDetails.ipAddressV4
   - networkConnectionAction.remoteIpDetails.ipAddressV4
   - awsApiCallAction.remoteIpDetails.ipAddressV4
   - dnsRequestAction.remoteIpDetails.ipAddressV4
3. WAF deny-ipsetの現在のアドレスリストを取得
4. 新規IPのみ /32 形式で追加
5. deny-ipsetを更新
6. 結果をログ出力して返却
```

---

## 7. クレデンシャル管理 詳細設計

### 7.1 SSM Parameter Store

| パラメータ名 | タイプ | 用途 | 事前登録 |
|-------------|--------|------|---------|
| /hcsa/rds/master_password | SecureString | RDSマスターパスワード | 必要 |

### 7.2 キーペア

| キー名 | 用途 | 管理方法 |
|--------|------|---------|
| id_rsa_aws | EC2 SSH接続（バックアップ用） | ローカル保管、gitignore対象 |

---

## 8. タグ詳細設計

### 8.1 リソース別タグ一覧

| リソース | Name タグ | 追加タグ |
|---------|-----------|---------|
| prod VPC | xxxx-x-prod-hcsa-vpc | - |
| onprem VPC | xxxx-x-onprem-hcsa-vpc | - |
| AppServer | xxxx-x-hcsa-appserver-prod-01 | Application=app-server |
| RouterPC | xxxx-x-hcsa-routerpc-dev-01 | Application=router |
| UserPC | xxxx-x-hcsa-userpc-dev-01 | Application=user-terminal |
| RDS | xxxx-x-prod-hcsa-rds | SecurityLevel=confidential |
| VPN Gateway | xxxx-x-prod-hcsa-vgw | - |
| Customer GW | xxxx-x-onprem-cgw | - |
| Lambda | xxxx-x-hcsa-block-attacker | - |

### 8.2 共通タグ（全リソース）

```hcl
{
  "xxxx-x"      = "true"
  "Project"     = "Hybrid-Cloud-Connectivity-and-Security-Automation"
  "Environment" = "prod"  # or "dev"
  "Owner"       = "dev-user1"
  "ManagedBy"   = "Terraform"
}
```

---

## 9. Terraform実装設計

### 9.1 ファイル構成と責務

| ファイル | 責務 | 依存先 |
|---------|------|--------|
| provider.tf | プロバイダ・バージョン制約 | なし |
| locals.tf | プレフィックス、タグ、IPリスト | なし |
| variables.tf | 入力変数 | なし |
| data.tf | AMI、SSM | variables.tf |
| main.tf | VPC、ルートテーブル、IGW | modules/vpc |
| vpn.tf | VGW、CGW、VPN接続、EIP | main.tf |
| security_groups.tf | 全SG | main.tf, vpn.tf |
| network_acl.tf | 全ACL | main.tf |
| iam.tf | 全IAMリソース | waf.tf |
| ec2.tf | 全EC2 | security_groups.tf, iam.tf, vpn.tf |
| rds.tf | RDS | security_groups.tf, main.tf |
| waf.tf | WAF IPSet | locals.tf |
| guardduty.tf | GuardDuty、EventBridge、Lambda | iam.tf, waf.tf |
| outputs.tf | 出力値 | 全ファイル |

### 9.2 モジュールインターフェース

#### modules/vpc

**Input:**
| 変数 | 型 | 説明 |
|------|-----|------|
| cidr_block | string | VPC CIDR |
| name | string | VPC名 |
| public_subnets | list(string) | パブリックサブネットCIDR |
| private_subnets | list(string) | プライベートサブネットCIDR |
| azs | list(string) | AZリスト |
| tags | map(string) | 共通タグ |

**Output:**
| 出力 | 型 | 説明 |
|------|-----|------|
| vpc_id | string | VPC ID |
| public_subnet_ids | list(string) | パブリックサブネットID |
| private_subnet_ids | list(string) | プライベートサブネットID |

#### modules/ec2

**Input:**
| 変数 | 型 | 説明 |
|------|-----|------|
| ami | string | AMI ID |
| instance_type | string | インスタンスタイプ |
| subnet_id | string | サブネットID |
| security_group_ids | list(string) | SG IDリスト |
| key_name | string | キーペア名 |
| associate_public_ip_address | bool | パブリックIP付与 |
| name | string | インスタンス名 |
| tags | map(string) | 共通タグ |
| userdata | string | user_data |
| iam_instance_profile | string | IAMプロファイル名 |
| source_dest_check | bool | 送信元/先チェック |

**Output:**
| 出力 | 型 | 説明 |
|------|-----|------|
| instance_id | string | インスタンスID |
| private_ip | string | プライベートIP |
| public_ip | string | パブリックIP |
