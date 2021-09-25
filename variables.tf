variable "db_name" {
  description = "RDS database name"
  type        = string
  sensitive   = true
}

variable "db_admin_user" {
  description = "RDS root user name"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "RDS root user password"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Primary domain name"
  type        = string
}

variable "key_name" {
  description = "Primary domain name"
  type        = string
}

variable "admin_ip_range" {
  description = "IP range to allow admin access from"
  type        = string
}