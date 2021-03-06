output "database_ip" {
  description = "DB server IP"
  value  = aws_instance.db_server.public_ip
}

output "public_ip" {
  description = "Public Elastic IP"
  value  = aws_eip.public_ip.public_ip
}