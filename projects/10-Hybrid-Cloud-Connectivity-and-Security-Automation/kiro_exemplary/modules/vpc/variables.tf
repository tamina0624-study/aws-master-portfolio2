variable "cidr_block" {
  description = "VPC CIDRブロック"
  type        = string
}

variable "name" {
  description = "VPC名"
  type        = string
}

variable "public_subnets" {
  description = "パブリックサブネットCIDRリスト"
  type        = list(string)
}

variable "private_subnets" {
  description = "プライベートサブネットCIDRリスト"
  type        = list(string)
}

variable "azs" {
  description = "アベイラビリティゾーンリスト"
  type        = list(string)
}

variable "tags" {
  description = "共通タグ"
  type        = map(string)
}
