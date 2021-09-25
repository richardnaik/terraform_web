output "public_ip" {
  description = "Public Elastic IP"
  value       = aws_eip.public_ip.public_ip
}

output "rds_hostname" {
  description = "RDS instance hostname"
  value       = aws_db_instance.db.address
}