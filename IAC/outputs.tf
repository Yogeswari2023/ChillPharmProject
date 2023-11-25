output "db_host" {
  value = aws_db_instance.main.address
}

output "bastion_host" {
  value = aws_instance.whoami.public_dns
}

output "api_endpoint" {
  value = aws_route53_record.app.fqdn
}