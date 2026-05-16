# terraform/endpoints.tf

# 1. VPC Endpoints用 セキュリティグループ
# NodeからのHTTPS(443)通信のみを許可します
resource "aws_security_group" "vpc_endpoints" {
  name        = "11-vpc-endpoints-sg"
  description = "Security group for VPC Endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.node_sg.id] # あとで定義するNode SGからの通信を許可
  }

  tags = { Name = "11-vpc-endpoints-sg" }
}

# 2. Interface型エンドポイント (SSM関連)
locals {
  services = ["ssm", "ssmmessages", "ec2messages"]
}

resource "aws_vpc_endpoint" "ssm_endpoints" {
  for_each = toset(local.services)

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.us-east-2.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_1a.id, aws_subnet.private_1c.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true # これによりNodeが標準のURLでプライベート接続できるようになります

  tags = { Name = "11-ssm-endpoint-${each.value}" }
}

# 3. Gateway型エンドポイント (S3用)
# S3は通信量が多くなりがちなので、無料で広帯域なGateway型を採用します
resource "aws_vpc_endpoint" "s3_gateway" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-east-2.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = { Name = "11-s3-gateway-endpoint" }
}
