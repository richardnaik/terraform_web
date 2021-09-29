variable "domain_name" {
  description = "Primary domain name"
  type        = string
}

variable "key_name" {
  description = "Key pair for SSH into the EC2 instances"
  type        = string
}

variable "admin_ip_range" {
  description = "IP range to allow admin access from"
  type        = string
}