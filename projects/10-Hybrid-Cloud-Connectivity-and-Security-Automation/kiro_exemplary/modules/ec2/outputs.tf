output "instance_id" {
  description = "EC2インスタンスID"
  value       = aws_instance.this.id
}

output "private_ip" {
  description = "プライベートIPアドレス"
  value       = aws_instance.this.private_ip
}

output "public_ip" {
  description = "パブリックIPアドレス"
  value       = aws_instance.this.public_ip
}
