###############################################################################
# EC2 Instances
###############################################################################

# --- アプリケーションサーバー (AWS VPC, パブリックサブネット) ---
module "appserver" {
  source                      = "./modules/ec2"
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t2.micro"
  subnet_id                   = module.prod_vpc.public_subnet_ids[0]
  key_name                    = var.key_name
  associate_public_ip_address = true
  name                        = "${local.prefix}-hcsa-appserver-prod-01"
  tags                        = local.common_tags
  security_group_ids          = [aws_security_group.prod_app.id]
  iam_instance_profile        = aws_iam_instance_profile.appserver.name
  userdata = templatefile(
    "${path.module}/modules/ec2/appserver_userdata.sh.tpl",
    {
      rds_endpoint = aws_db_instance.prod_rds.endpoint
      rds_user     = var.rds_master_username
      rds_pass     = data.aws_ssm_parameter.rds_password.value
      rds_db       = "hcsa_db"
    }
  )
}

# --- ルーター端末 (疑似オンプレVPC, Ubuntu) ---
module "routerpc" {
  source                      = "./modules/ec2"
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = module.onprem_vpc.public_subnet_ids[0]
  key_name                    = var.key_name
  associate_public_ip_address = true
  name                        = "${local.prefix}-hcsa-routerpc-dev-01"
  tags                        = local.common_tags
  security_group_ids          = [aws_security_group.onprem.id]
  iam_instance_profile        = aws_iam_instance_profile.routerpc.name
  userdata = templatefile(
    "${path.module}/modules/ec2/vpn_setup.sh.tpl",
    {
      tun1_outside_ip        = aws_vpn_connection.onprem.tunnel1_address
      tun2_outside_ip        = aws_vpn_connection.onprem.tunnel2_address
      onprem_public_ip       = aws_eip.onprem_router.public_ip
      tun1_psk               = aws_vpn_connection.onprem.tunnel1_preshared_key
      tun2_psk               = aws_vpn_connection.onprem.tunnel2_preshared_key
      tun1_inside_cgw_ip     = aws_vpn_connection.onprem.tunnel1_cgw_inside_address
      tun1_inside_vgw_ip     = aws_vpn_connection.onprem.tunnel1_vgw_inside_address
      tun2_inside_cgw_ip     = aws_vpn_connection.onprem.tunnel2_cgw_inside_address
      tun2_inside_vgw_ip     = aws_vpn_connection.onprem.tunnel2_vgw_inside_address
      tun1_inside_cidr_block = aws_vpn_connection.onprem.tunnel1_inside_cidr
      tun2_inside_cidr_block = aws_vpn_connection.onprem.tunnel2_inside_cidr
      aws_bgp_asn            = var.aws_bgp_asn
      onprem_bgp_asn         = var.onprem_bgp_asn
    }
  )
}

# --- ユーザー操作端末 (疑似オンプレVPC) ---
module "userpc" {
  source                      = "./modules/ec2"
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t2.micro"
  subnet_id                   = module.onprem_vpc.public_subnet_ids[0]
  key_name                    = var.key_name
  associate_public_ip_address = true
  name                        = "${local.prefix}-hcsa-userpc-dev-01"
  tags                        = local.common_tags
  security_group_ids          = [aws_security_group.onprem.id]
  iam_instance_profile        = aws_iam_instance_profile.userpc.name
}
