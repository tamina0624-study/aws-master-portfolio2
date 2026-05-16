###############################################################################
# WAF v2 - IP Sets
###############################################################################

# 許可IPセット（VPC内部CIDR）
resource "aws_wafv2_ip_set" "allow" {
  name               = "${local.prefix}-allow-ipset"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = local.internal_cidrs
  tags               = merge(local.common_tags, { Name = "${local.prefix}-allow-ipset" })
}

# 拒否IPセット（初期は空、GuardDuty検知時にLambdaが追加）
# NOTE: Terraformでは空リストが許可されないため、ダミーアドレスを設定
resource "aws_wafv2_ip_set" "deny" {
  name               = "${local.prefix}-deny-ipset"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = ["255.255.255.255/32"]
  tags               = merge(local.common_tags, { Name = "${local.prefix}-deny-ipset" })

  lifecycle {
    ignore_changes = [addresses]
  }
}
