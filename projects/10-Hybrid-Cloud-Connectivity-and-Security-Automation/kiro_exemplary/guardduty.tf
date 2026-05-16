###############################################################################
# GuardDuty + EventBridge + Lambda (自動防御)
###############################################################################

# GuardDuty Detector
resource "aws_guardduty_detector" "main" {
  enable = true
  tags   = local.common_tags
}

# EventBridgeルール: GuardDuty Finding → Lambda
resource "aws_cloudwatch_event_rule" "guardduty_finding" {
  name        = "${local.prefix}-hcsa-guardduty-to-lambda"
  description = "GuardDuty FindingをLambdaへ転送し自動防御を実行"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      type = [
        { prefix = "UnauthorizedAccess" },
        { prefix = "Recon" },
        { prefix = "Trojan" },
        { prefix = "Backdoor" },
        { prefix = "CryptoCurrency" },
        { prefix = "Impact" },
        { prefix = "Persistence" },
        { prefix = "PenTest" },
        { prefix = "Behavior" },
      ]
    }
  })

  tags = local.common_tags
}

# EventBridgeターゲット: Lambda
resource "aws_cloudwatch_event_target" "guardduty_to_lambda" {
  rule = aws_cloudwatch_event_rule.guardduty_finding.name
  arn  = aws_lambda_function.block_attacker.arn
}

# Lambda実行許可 (EventBridgeから)
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.block_attacker.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.guardduty_finding.arn
}

# Lambda関数: 攻撃元IPブロック
resource "aws_lambda_function" "block_attacker" {
  function_name    = "${local.prefix}-hcsa-block-attacker"
  role             = aws_iam_role.lambda_block_attacker.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  timeout          = 10
  memory_size      = 128
  filename         = "${path.module}/modules/lambda/lambda_function.zip"
  source_code_hash = filebase64sha256("${path.module}/modules/lambda/lambda_function.zip")

  environment {
    variables = {
      WAFV2_IP_SET_ID   = aws_wafv2_ip_set.deny.id
      WAFV2_IP_SET_NAME = aws_wafv2_ip_set.deny.name
      WAFV2_SCOPE       = "REGIONAL"
    }
  }

  tags = local.common_tags
}
