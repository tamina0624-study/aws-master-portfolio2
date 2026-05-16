# terraform/eks.tf

# 1. EKS クラスター本体
resource "aws_eks_cluster" "main" {
  name     = "11-devsecops-cluster"
  role_arn = aws_iam_role.cluster_role.arn
  version  = "1.30"

  vpc_config {
    subnet_ids              = [aws_subnet.private_1a.id, aws_subnet.private_1c.id]
    security_group_ids      = [aws_security_group.node_sg.id] # クラスター管理用
    endpoint_private_access = true  # VPC内部からのAPIアクセスを許可
    endpoint_public_access  = true  # 管理者IPからの外部アクセスを許可
    public_access_cidrs     = [var.admin_allow_ip_cidr] # variables.tfで定義
  }

  # EKS Access Entry 方式を有効化（推奨される新しい認証方式）
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy
  ]
}

# 2. マネージドノードグループ
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "11-main-node-group"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = [aws_subnet.private_1a.id, aws_subnet.private_1c.id]

  instance_types = ["t3.medium"]
  ami_type       = "AL2023_x86_64_STANDARD" # 最新のAmazon Linux 2023ベース
  capacity_type  = "ON_DEMAND"

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 4
  }

  update_config {
    max_unavailable = 1
  }

  # NodeへのSSH(22)は閉じ、SSMログインのみとするため remote_access は設定しない

  depends_on = [
    aws_iam_role_policy_attachment.node_policy_attachments
  ]

  tags = {
    Name = "11-eks-node"
  }
}

# 3. OIDC Provider (IRSA: PodにIAM権限を渡すために必須)
data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# GitHub Actions 用のロールを EKS の管理者に設定
resource "aws_eks_access_entry" "github_actions" {
  cluster_name      = aws_eks_cluster.main.name
  principal_arn     = aws_iam_role.github_actions.arn
  type              = "STANDARD"
}

resource "aws_eks_access_policy_association" "github_actions_admin" {
  cluster_name  = aws_eks_cluster.main.name
  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_iam_role.github_actions.arn

  access_scope {
    type = "cluster"
  }
}
