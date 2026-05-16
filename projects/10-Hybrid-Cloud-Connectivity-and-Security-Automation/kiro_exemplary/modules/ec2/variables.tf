variable "ami" {
  description = "AMI ID"
  type        = string
}

variable "instance_type" {
  description = "EC2インスタンスタイプ"
  type        = string
}

variable "subnet_id" {
  description = "配置先サブネットID"
  type        = string
}

variable "security_group_ids" {
  description = "セキュリティグループIDリスト"
  type        = list(string)
}

variable "key_name" {
  description = "SSHキーペア名"
  type        = string
  default     = null
}

variable "associate_public_ip_address" {
  description = "パブリックIPを付与するか"
  type        = bool
  default     = false
}

variable "name" {
  description = "インスタンス名タグ"
  type        = string
}

variable "tags" {
  description = "共通タグ"
  type        = map(string)
}

variable "userdata" {
  description = "EC2 user_data スクリプト"
  type        = string
  default     = null
}

variable "iam_instance_profile" {
  description = "IAMインスタンスプロファイル名"
  type        = string
  default     = null
}

variable "source_dest_check" {
  description = "送信元/送信先チェック（ルーター用にfalse）"
  type        = bool
  default     = false
}
