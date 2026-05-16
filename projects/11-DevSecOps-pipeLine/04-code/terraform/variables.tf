# terraform/variables.tf

variable "admin_allow_ip_cidr" {
  description = "管理者（あなた）のパブリックIP (例: 203.0.113.1/32)"
  type        = string
}
