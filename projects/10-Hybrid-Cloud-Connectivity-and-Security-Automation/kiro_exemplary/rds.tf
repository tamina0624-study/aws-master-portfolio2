###############################################################################
# RDS (MySQL)
# ルール: プライベートサブネット配置、パブリックアクセス無効、IAM認証有効
###############################################################################

# サブネットグループ
resource "aws_db_subnet_group" "prod" {
  name       = "${local.prefix}-prod-hcsa-rds-subnet-group"
  subnet_ids = module.prod_vpc.private_subnet_ids
  tags       = merge(local.common_tags, { Name = "${local.prefix}-prod-hcsa-rds-subnet-group" })
}

# RDSインスタンス
resource "aws_db_instance" "prod_rds" {
  identifier     = "${local.prefix}-prod-hcsa-rds"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t4g.micro"

  allocated_storage = 20
  storage_type      = "gp2"

  db_subnet_group_name   = aws_db_subnet_group.prod.name
  vpc_security_group_ids = [aws_security_group.prod_rds.id]

  username = var.rds_master_username
  password = data.aws_ssm_parameter.rds_password.value
  db_name  = "hcsa_db"

  multi_az            = false
  availability_zone   = var.azs[0]
  publicly_accessible = false

  skip_final_snapshot = true
  deletion_protection = false

  iam_database_authentication_enabled = true

  tags = merge(local.common_tags, {
    Name          = "${local.prefix}-prod-hcsa-rds"
    SecurityLevel = "confidential"
  })
}
