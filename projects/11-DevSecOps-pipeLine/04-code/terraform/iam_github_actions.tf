# terraform/iam_github_actions.tf

# 1. GitHub OIDC プロバイダーの設定
# これにより、AWSが「GitHubからのアクセス」を信頼するようになります。
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
}

# 2. GitHub Actions 用の IAM ロール
resource "aws_iam_role" "github_actions" {
  name = "11-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringLike = {
            # あなたのGitHubユーザー名/リポジトリ名のみに権限を絞ります
            "token.actions.githubusercontent.com:sub" = "repo:tamina0624-study/react_test_app:*"
          }
        }
      }
    ]
  })
}

# 3. ロールに権限を付与（ECRプッシュとEKSへのアクセス権限）
resource "aws_iam_role_policy_attachment" "github_actions_ecr" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# EKSの情報を取得するための権限も追加
resource "aws_iam_role_policy_attachment" "github_actions_eks" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}
