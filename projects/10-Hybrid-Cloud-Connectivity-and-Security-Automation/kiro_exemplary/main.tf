###############################################################################
# VPC Modules
###############################################################################

# AWS側VPC (本番環境)
module "prod_vpc" {
  source          = "./modules/vpc"
  cidr_block      = var.prod_vpc_cidr
  name            = "${local.prefix}-prod-hcsa-vpc"
  public_subnets  = var.prod_public_subnets
  private_subnets = var.prod_private_subnets
  azs             = var.azs
  tags            = local.common_tags
}

# 疑似オンプレVPC
module "onprem_vpc" {
  source          = "./modules/vpc"
  cidr_block      = var.onprem_vpc_cidr
  name            = "${local.prefix}-onprem-hcsa-vpc"
  public_subnets  = var.onprem_public_subnets
  private_subnets = var.onprem_private_subnets
  azs             = var.azs
  tags            = local.common_tags
}

###############################################################################
# Internet Gateways
###############################################################################

resource "aws_internet_gateway" "prod" {
  vpc_id = module.prod_vpc.vpc_id
  tags   = merge(local.common_tags, { Name = "${local.prefix}-prod-hcsa-igw" })
}

resource "aws_internet_gateway" "onprem" {
  vpc_id = module.onprem_vpc.vpc_id
  tags   = merge(local.common_tags, { Name = "${local.prefix}-onprem-hcsa-igw" })
}

###############################################################################
# Route Tables
###############################################################################

# AWS側: パブリックサブネット用
resource "aws_route_table" "prod_public" {
  vpc_id = module.prod_vpc.vpc_id
  tags   = merge(local.common_tags, { Name = "${local.prefix}-prod-public-rtb" })
}

resource "aws_route" "prod_public_igw" {
  route_table_id         = aws_route_table.prod_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.prod.id
}

resource "aws_route_table_association" "prod_public" {
  count          = length(module.prod_vpc.public_subnet_ids)
  subnet_id      = module.prod_vpc.public_subnet_ids[count.index]
  route_table_id = aws_route_table.prod_public.id
}

# AWS側: プライベートサブネット用
resource "aws_route_table" "prod_private" {
  vpc_id = module.prod_vpc.vpc_id
  tags   = merge(local.common_tags, { Name = "${local.prefix}-prod-private-rtb" })
}

resource "aws_route_table_association" "prod_private" {
  count          = length(module.prod_vpc.private_subnet_ids)
  subnet_id      = module.prod_vpc.private_subnet_ids[count.index]
  route_table_id = aws_route_table.prod_private.id
}

# VPN経路伝播（プライベートサブネットへオンプレ宛ルートを伝播）
resource "aws_vpn_gateway_route_propagation" "prod_private" {
  vpn_gateway_id = aws_vpn_gateway.prod.id
  route_table_id = aws_route_table.prod_private.id
}

# オンプレ側ルートテーブル
resource "aws_route_table" "onprem" {
  vpc_id = module.onprem_vpc.vpc_id
  tags   = merge(local.common_tags, { Name = "${local.prefix}-onprem-hcsa-rtb" })
}

resource "aws_route" "onprem_igw" {
  route_table_id         = aws_route_table.onprem.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.onprem.id
}

resource "aws_route_table_association" "onprem_public" {
  count          = length(module.onprem_vpc.public_subnet_ids)
  subnet_id      = module.onprem_vpc.public_subnet_ids[count.index]
  route_table_id = aws_route_table.onprem.id
}

resource "aws_route_table_association" "onprem_private" {
  count          = length(module.onprem_vpc.private_subnet_ids)
  subnet_id      = module.onprem_vpc.private_subnet_ids[count.index]
  route_table_id = aws_route_table.onprem.id
}
