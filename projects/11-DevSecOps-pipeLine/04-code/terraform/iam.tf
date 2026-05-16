# terraform/iam.tf

# 1. EKS クラスター用 IAM ロール
resource "aws_iam_role" "cluster_role" {
  name = "11-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster_role.name
}

# 2. EKS ワーカーノード用 IAM ロール
resource "aws_iam_role" "node_role" {
  name = "11-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# ノードに必要な標準ポリシーのセット
locals {
  node_policies = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",          # EKSノードの基本動作
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",               # PodへのIP付与用
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly", # ECRからのプル用
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"        # SSM Session Managerログイン用 (重要)
  ]
}

resource "aws_iam_role_policy_attachment" "node_policy_attachments" {
  for_each   = toset(local.node_policies)
  policy_arn = each.value
  role       = aws_iam_role.node_role.name
}

# terraform/iam.tf (修正版)

# 1. 信頼関係（Trust Policy）の定義
resource "aws_iam_role" "alb_controller_role" {
  name = "11-aws-load-balancer-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }]
  })
}

# 2. LBCに必要な権限ポリシーのアタッチ
# 注意：本来はAWSが配布する専用のJSONポリシーが必要ですが、
# 学習用として一旦 PowerUserAccess もしくは ALB関連のマネージドポリシーを当てます。
# 本番想定なら：https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json を使用
resource "aws_iam_role_policy_attachment" "alb_controller_attach" {
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
  role       = aws_iam_role.alb_controller_role.name
}

# 追加で必要なEC2権限
resource "aws_iam_role_policy_attachment" "alb_controller_ec2_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
  role       = aws_iam_role.alb_controller_role.name
}


resource "aws_iam_policy" "custom_policy" {
  name = "create-securitygroup-kubernetes"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ec2:CreateSecurityGroup",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:CreateTags"
            ],
            "Resource": "*"
        }
    ]
})
}


# 追加で必要なEC2権限
resource "aws_iam_role_policy_attachment" "alb_controller_sg_attach" {

  policy_arn = aws_iam_policy.custom_policy.arn
  role       = aws_iam_role.alb_controller_role.name
}




data "aws_caller_identity" "current" {}
