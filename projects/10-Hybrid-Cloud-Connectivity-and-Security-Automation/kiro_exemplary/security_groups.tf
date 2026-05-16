###############################################################################
# Security Groups
# ルール: 最小権限、All Traffic禁止、0.0.0.0/0 port22禁止
###############################################################################

# --- AWS側VPC: アプリケーションサーバー用SG ---
resource "aws_security_group" "prod_app" {
  name        = "${local.prefix}-prod-hcsa-app-sg"
  description = "AppServer: internal VPC + VPN traffic only"
  vpc_id      = module.prod_vpc.vpc_id

  # VPC内部通信（TCP全ポート）
  ingress {
    description = "Internal VPC and VPN traffic"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = local.internal_cidrs
  }

  # ICMP (ping) - 内部のみ
  ingress {
    description = "ICMP from internal"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = local.internal_cidrs
  }

  # HTTP (Flask App) - 許可IPリストからのみ
  ingress {
    description = "HTTP from allowed IPs"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = local.allowed_ipv4_cidrs
  }

  # HTTPS - 許可IPリストからのみ
  ingress {
    description = "HTTPS from allowed IPs"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = local.allowed_ipv4_cidrs
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.prefix}-prod-hcsa-app-sg" })
}

# --- AWS側VPC: RDS用SG ---
resource "aws_security_group" "prod_rds" {
  name        = "${local.prefix}-prod-hcsa-rds-sg"
  description = "RDS: allow MySQL from AppServer SG only"
  vpc_id      = module.prod_vpc.vpc_id

  ingress {
    description     = "MySQL from AppServer"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.prod_app.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.prefix}-prod-hcsa-rds-sg" })
}

# --- オンプレVPC: 共通SG ---
resource "aws_security_group" "onprem" {
  name        = "${local.prefix}-onprem-hcsa-sg"
  description = "OnPrem VPC: internal + VPN + IKE traffic"
  vpc_id      = module.onprem_vpc.vpc_id

  # VPC内部通信
  ingress {
    description = "Internal VPC and VPN traffic"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = local.internal_cidrs
  }

  # ICMP - 内部のみ
  ingress {
    description = "ICMP from internal"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = local.internal_cidrs
  }

  # IKE (UDP 500) - VPNトンネルエンドポイントから
  ingress {
    description = "IKE from VPN tunnel endpoints"
    from_port   = 500
    to_port     = 500
    protocol    = "udp"
    cidr_blocks = [
      "${aws_vpn_connection.onprem.tunnel1_address}/32",
      "${aws_vpn_connection.onprem.tunnel2_address}/32",
    ]
  }

  # NAT-T (UDP 4500) - VPNトンネルエンドポイントから
  ingress {
    description = "NAT-T from VPN tunnel endpoints"
    from_port   = 4500
    to_port     = 4500
    protocol    = "udp"
    cidr_blocks = [
      "${aws_vpn_connection.onprem.tunnel1_address}/32",
      "${aws_vpn_connection.onprem.tunnel2_address}/32",
    ]
  }

  # SSH - 許可IPリストからのみ（管理用、SSM推奨だがオンプレ模擬のため許可）
  ingress {
    description = "SSH from allowed IPs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.allowed_ipv4_cidrs
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.prefix}-onprem-hcsa-sg" })
}
