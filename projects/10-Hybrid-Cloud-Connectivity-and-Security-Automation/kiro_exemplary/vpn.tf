###############################################################################
# VPN Configuration
###############################################################################

# オンプレ側ルーター用 Elastic IP
resource "aws_eip" "onprem_router" {
  domain = "vpc"
  tags   = merge(local.common_tags, { Name = "${local.prefix}-onprem-router-eip" })
}

# 仮想プライベートゲートウェイ (VGW)
resource "aws_vpn_gateway" "prod" {
  vpc_id          = module.prod_vpc.vpc_id
  amazon_side_asn = var.aws_bgp_asn
  tags            = merge(local.common_tags, { Name = "${local.prefix}-prod-hcsa-vgw" })
}

# カスタマーゲートウェイ (CGW)
resource "aws_customer_gateway" "onprem" {
  bgp_asn    = var.onprem_bgp_asn
  ip_address = aws_eip.onprem_router.public_ip
  type       = "ipsec.1"
  tags       = merge(local.common_tags, { Name = "${local.prefix}-onprem-cgw" })
}

# VPN接続 (Site-to-Site, BGP有効)
resource "aws_vpn_connection" "onprem" {
  vpn_gateway_id      = aws_vpn_gateway.prod.id
  customer_gateway_id = aws_customer_gateway.onprem.id
  type                = "ipsec.1"
  static_routes_only  = false
  tags                = merge(local.common_tags, { Name = "${local.prefix}-onprem-vpn" })
}

# EIP紐づけ（ルーターEC2へ）
resource "aws_eip_association" "onprem_router" {
  instance_id   = module.routerpc.instance_id
  allocation_id = aws_eip.onprem_router.id
}
