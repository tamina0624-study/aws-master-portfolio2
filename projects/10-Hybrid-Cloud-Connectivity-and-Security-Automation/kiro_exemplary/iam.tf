###############################################################################
# IAM Roles & Policies
# ルール: 最小権限、AdministratorAccess禁止
###############################################################################

# --- EC2: AppServer Role ---
resource "aws_iam_role" "appserver" {
  name               = "${local.prefix}-hcsa-ec2-appserver-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "appserver_ssm" {
  role       = aws_iam_role.appserver.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "appserver_cloudwatch" {
  role       = aws_iam_role.appserver.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# RDS接続用カスタムポリシー（最小権限: rds-db:connect のみ）
resource "aws_iam_policy" "appserver_rds_connect" {
  name        = "${local.prefix}-hcsa-appserver-rds-connect"
  description = "Allow RDS IAM authentication connect"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["rds-db:connect"]
        Resource = ["arn:aws:rds-db:${var.region}:*:dbuser:*/admin"]
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "appserver_rds" {
  role       = aws_iam_role.appserver.name
  policy_arn = aws_iam_policy.appserver_rds_connect.arn
}

resource "aws_iam_instance_profile" "appserver" {
  name = "${local.prefix}-hcsa-ec2-appserver-profile"
  role = aws_iam_role.appserver.name
}

# --- EC2: RouterPC Role ---
resource "aws_iam_role" "routerpc" {
  name               = "${local.prefix}-hcsa-ec2-routerpc-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "routerpc_ssm" {
  role       = aws_iam_role.routerpc.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "routerpc_cloudwatch" {
  role       = aws_iam_role.routerpc.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "routerpc" {
  name = "${local.prefix}-hcsa-ec2-routerpc-profile"
  role = aws_iam_role.routerpc.name
}

# --- EC2: UserPC Role ---
resource "aws_iam_role" "userpc" {
  name               = "${local.prefix}-hcsa-ec2-userpc-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "userpc_ssm" {
  role       = aws_iam_role.userpc.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "userpc_cloudwatch" {
  role       = aws_iam_role.userpc.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "userpc" {
  name = "${local.prefix}-hcsa-ec2-userpc-profile"
  role = aws_iam_role.userpc.name
}

# --- Lambda: Block Attacker Role ---
resource "aws_iam_role" "lambda_block_attacker" {
  name               = "${local.prefix}-hcsa-lambda-block-attacker-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_block_attacker.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "lambda_security_actions" {
  name        = "${local.prefix}-hcsa-lambda-security-actions"
  description = "Allow Lambda to update WAF IP sets and security groups"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "wafv2:GetIPSet",
          "wafv2:UpdateIPSet",
        ]
        Resource = [aws_wafv2_ip_set.deny.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DescribeSecurityGroups",
        ]
        Resource = ["*"]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkAclEntry",
          "ec2:DeleteNetworkAclEntry",
          "ec2:ReplaceNetworkAclEntry",
          "ec2:DescribeNetworkAcls",
        ]
        Resource = ["*"]
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_security" {
  role       = aws_iam_role.lambda_block_attacker.name
  policy_arn = aws_iam_policy.lambda_security_actions.arn
}
