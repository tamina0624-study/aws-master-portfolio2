# terraform/ecr.tf

resource "aws_ecr_repository" "app" {
  name                 = "11-react-app"
  image_tag_mutability = "IMMUTABLE" # 同じタグでの上書きを禁止（安全のため）

  image_scanning_configuration {
    scan_on_push = true # プッシュ時に脆弱性診断を自動実行
  }

  tags = {
    Name = "11-react-app-repo"
  }
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}
