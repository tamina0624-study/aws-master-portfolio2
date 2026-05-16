###############################################################################
# Network ACLs
# 方針: 基本Allow + 最低限のDeny（シンプルに保つ）
###############################################################################

# --- AWS側VPC ACL ---
resource "aws_network_acl" "prod" {
  vpc_id     = module.prod_vpc.vpc_id
  subnet_ids = concat(module.prod_vpc.public_subnet_ids, module.prod_vpc.private_subnet_ids)

  # Inbound: ICMP許可
  ingress {
    rule_no    = 10
    protocol   = "icmp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
    icmp_type  = -1
    icmp_code  = -1
  }

  # Inbound: VPC内部通信許可
  ingress {
    rule_no    = 20
    protocol   = "-1"
    action     = "allow"
    cidr_block = var.prod_vpc_cidr
    from_port  = 0
    to_port    = 0
  }

  # Inbound: オンプレVPCからの通信許可
  ingress {
    rule_no    = 30
    protocol   = "-1"
    action     = "allow"
    cidr_block = var.onprem_vpc_cidr
    from_port  = 0
    to_port    = 0
  }

  # Inbound: エフェメラルポート許可（戻り通信用）
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Inbound: HTTP (許可IPからのWeb UI)
  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  # Inbound: HTTPS
  ingress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Inbound: 最終Deny
  ingress {
    rule_no    = 32766
    protocol   = "-1"
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  # Outbound: 全許可
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(local.common_tags, { Name = "${local.prefix}-prod-hcsa-acl" })
}

# --- オンプレVPC ACL ---
resource "aws_network_acl" "onprem" {
  vpc_id     = module.onprem_vpc.vpc_id
  subnet_ids = concat(module.onprem_vpc.public_subnet_ids, module.onprem_vpc.private_subnet_ids)

  # Inbound: ICMP許可
  ingress {
    rule_no    = 10
    protocol   = "icmp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
    icmp_type  = -1
    icmp_code  = -1
  }

  # Inbound: VPC内部通信許可
  ingress {
    rule_no    = 20
    protocol   = "-1"
    action     = "allow"
    cidr_block = var.onprem_vpc_cidr
    from_port  = 0
    to_port    = 0
  }

  # Inbound: AWS VPCからの通信許可
  ingress {
    rule_no    = 30
    protocol   = "-1"
    action     = "allow"
    cidr_block = var.prod_vpc_cidr
    from_port  = 0
    to_port    = 0
  }

  # Inbound: IKE/NAT-T (VPN用 UDP)
  ingress {
    rule_no    = 40
    protocol   = "udp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 500
    to_port    = 500
  }

  ingress {
    rule_no    = 41
    protocol   = "udp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 4500
    to_port    = 4500
  }

  # Inbound: エフェメラルポート許可
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Inbound: SSH (許可IPからのみ)
  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  # Inbound: 最終Deny
  ingress {
    rule_no    = 32766
    protocol   = "-1"
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  # Outbound: 全許可
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(local.common_tags, { Name = "${local.prefix}-onprem-hcsa-acl" })
}
