# terraform/security_groups.tf

# 1. ALB用 セキュリティグループ (インターネットからの入り口)
resource "aws_security_group" "alb_sg" {
  name        = "11-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  # インターネットからのHTTP通信を許可
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.admin_allow_ip_cidr]
  }

  # インターネットからのHTTPS通信を許可
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.admin_allow_ip_cidr]
  }

  # Node SG への全通信を許可
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "11-alb-sg" }
}

# 2. EKS Node用 セキュリティグループ (アプリケーション実行環境)
resource "aws_security_group" "node_sg" {
  name        = "11-eks-node-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = aws_vpc.main.id

  # ALBからのトラフィックを直接Pod（ポート80）で受けるための許可
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # クラスター内の通信 (CoreDNSやNode間通信)
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  # アウトバウンド通信 (ECR/SSM/インターネットへの通信をNATGW経由で許可)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "11-eks-node-sg" }
}
