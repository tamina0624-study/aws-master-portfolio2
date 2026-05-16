###############################################################################
# Outputs
###############################################################################

# VPC
output "prod_vpc_id" {
  description = "AWS側VPC ID"
  value       = module.prod_vpc.vpc_id
}

output "onprem_vpc_id" {
  description = "疑似オンプレVPC ID"
  value       = module.onprem_vpc.vpc_id
}

# Subnets
output "prod_public_subnet_ids" {
  description = "AWS側パブリックサブネットID"
  value       = module.prod_vpc.public_subnet_ids
}

output "prod_private_subnet_ids" {
  description = "AWS側プライベートサブネットID"
  value       = module.prod_vpc.private_subnet_ids
}

# EC2
output "appserver_instance_id" {
  description = "AppServer EC2 Instance ID"
  value       = module.appserver.instance_id
}

output "routerpc_instance_id" {
  description = "RouterPC EC2 Instance ID"
  value       = module.routerpc.instance_id
}

output "userpc_instance_id" {
  description = "UserPC EC2 Instance ID"
  value       = module.userpc.instance_id
}

# RDS
output "rds_endpoint" {
  description = "RDSエンドポイント"
  value       = aws_db_instance.prod_rds.endpoint
}

# VPN
output "vpn_connection_id" {
  description = "VPN接続ID"
  value       = aws_vpn_connection.onprem.id
}

output "vpn_tunnel1_address" {
  description = "VPNトンネル1外部IP"
  value       = aws_vpn_connection.onprem.tunnel1_address
}

output "vpn_tunnel2_address" {
  description = "VPNトンネル2外部IP"
  value       = aws_vpn_connection.onprem.tunnel2_address
}

# Security
output "guardduty_detector_id" {
  description = "GuardDuty Detector ID"
  value       = aws_guardduty_detector.main.id
}

output "deny_ipset_id" {
  description = "WAF deny-ipset ID (Lambda環境変数用)"
  value       = aws_wafv2_ip_set.deny.id
}
