###############################################################################
# General Variables
###############################################################################

variable "region" {
  description = "AWSリージョン（us-east-1固定）"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "環境名（dev/stg/prod）"
  type        = string
  default     = "prod"
}

variable "owner" {
  description = "リソースオーナー名"
  type        = string
  default     = "dev-user1"
}

###############################################################################
# AWS側VPC (prod)
###############################################################################

variable "prod_vpc_cidr" {
  description = "AWS側VPCのCIDRブロック"
  type        = string
  default     = "10.0.0.0/16"
}

variable "prod_public_subnets" {
  description = "AWS側パブリックサブネットCIDRリスト"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "prod_private_subnets" {
  description = "AWS側プライベートサブネットCIDRリスト"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

###############################################################################
# 疑似オンプレVPC
###############################################################################

variable "onprem_vpc_cidr" {
  description = "疑似オンプレVPCのCIDRブロック"
  type        = string
  default     = "10.1.0.0/16"
}

variable "onprem_public_subnets" {
  description = "疑似オンプレVPCのパブリックサブネットCIDRリスト"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "onprem_private_subnets" {
  description = "疑似オンプレVPCのプライベートサブネットCIDRリスト"
  type        = list(string)
  default     = ["10.1.3.0/24", "10.1.4.0/24"]
}

###############################################################################
# Availability Zones
###############################################################################

variable "azs" {
  description = "使用するアベイラビリティゾーン"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

###############################################################################
# VPN
###############################################################################

variable "aws_bgp_asn" {
  description = "AWS側VGWのBGP ASN"
  type        = number
  default     = 65000
}

variable "onprem_bgp_asn" {
  description = "オンプレ側カスタマーゲートウェイのBGP ASN"
  type        = number
  default     = 65001
}

###############################################################################
# RDS
###############################################################################

variable "rds_master_username" {
  description = "RDSマスターユーザー名"
  type        = string
  default     = "admin"
}

variable "rds_password_ssm_parameter" {
  description = "RDSパスワードを格納するSSM Parameter Store名"
  type        = string
  default     = "/hcsa/rds/master_password"
}

###############################################################################
# EC2 Key Pair
###############################################################################

variable "key_name" {
  description = "EC2用キーペア名"
  type        = string
  default     = "id_rsa_aws"
}
