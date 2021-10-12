terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "us-east-2"
}

# VPC with one public subnet
module "web_vpc" {
  name = "web_vpc"
  source  = "terraform-aws-modules/vpc/aws"

  cidr = "10.0.0.0/16"
  azs = ["us-east-2c"]
  public_subnets = ["10.0.3.0/24"]
  enable_ipv6 = false
  enable_dns_support = true
  enable_dns_hostnames = true 

  vpc_tags = {
    Name = "web_vpc"
  }
}

# security group to allow web traffic globally and SSH to the admin IP range 
module "web_sg" {
  source = "terraform-aws-modules/security-group/aws"
  name = "web_sg"
  description = "web server security group"
  vpc_id = module.web_vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      rule = "ssh-tcp"
      cidr_blocks = var.admin_ip_range
    },
    {
      rule = "http-80-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      rule = "https-443-tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  
  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules = ["all-all"]
}

# security group to allow database traffic within the subnet plus SSH to the admin IP range 
module "db_sg" {
  source = "terraform-aws-modules/security-group/aws"
  name = "db_sg"
  description = "database security group"
  vpc_id = module.web_vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      rule = "ssh-tcp"
      cidr_blocks = var.admin_ip_range
    },
    {
      rule = "mysql-tcp"
      cidr_blocks = "10.0.3.0/24"
    }
  ]
  
  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules = ["all-all"]
}

# web server
resource "aws_instance" "web_server" {
  ami = "ami-086586d173a744e81"
  instance_type = "t3.medium"
  key_name = var.key_name
  root_block_device {
    volume_size           = "20"
    volume_type           = "gp3"
    delete_on_termination = "true"
  }

  subnet_id = module.web_vpc.public_subnets[0]
  vpc_security_group_ids = [module.web_sg.security_group_id]

  tags = {
    Name = "web_server"
  }
}

# database server
resource "aws_instance" "db_server" {
  ami = "ami-086586d173a744e81"
  instance_type = "t3.medium"
  key_name = var.key_name
  root_block_device {
    volume_size           = "20"
    volume_type           = "gp3"
    delete_on_termination = "true"
  }

  subnet_id = module.web_vpc.public_subnets[0]
  vpc_security_group_ids = [module.db_sg.security_group_id]

  tags = {
    Name = "db_server"
  }
}

# web storage volume and attachment
resource "aws_ebs_volume" "web_storage_volume" {
  availability_zone = "us-east-2c"
  size = 80
  type = "gp3"

  tags = {
    Name = "web_storage"
  }
}

resource "aws_volume_attachment" "web_storage_attachment" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.web_storage_volume.id
  instance_id = aws_instance.web_server.id
}

# database storage volume and attachment
resource "aws_ebs_volume" "db_storage_volume" {
  availability_zone = "us-east-2c"
  size = 20
  type = "gp3"

  tags = {
    Name = "db_storage"
  }
}

resource "aws_volume_attachment" "db_storage_attachment" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.db_storage_volume.id
  instance_id = aws_instance.db_server.id
}

# elastic IP for public use, attach to web server
resource "aws_eip" "public_ip" {
  vpc = true
  instance = aws_instance.web_server.id
}

# DNS zone and A record for domain name
resource "aws_route53_zone" "main" {
  name = var.domain_name
}

resource "aws_route53_record" "domain_name" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = "300"
  records = [aws_eip.public_ip.public_ip]
}

resource "aws_route53_record" "cname" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"
  type    = "CNAME"
  ttl     = "300"
  records = [var.domain_name]
}