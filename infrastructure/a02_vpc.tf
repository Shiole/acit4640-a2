terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.1"
    }
  }
  required_version = ">= 1.3.0"
}

# Variables 
variable "aws_region" {
  description = "AWS region"
  default     = "us-west-2"
}

variable "aws_az" {
  description = "AWS AZ"
  default     = "us-west-2a"
}


variable "project_name" {
  description = "Project name"
  default     = "a02"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  default     = "192.168.0.0/16"
}

variable "priv_subnet_cidr" {
  description = "Subnet CIDR"
  default     = "192.168.1.0/24"
}

variable "pub_subnet_cidr" {
  description = "Subnet CIDR"
  default     = "192.168.2.0/24"
}

variable "default_route" {
  description = "Default route"
  default     = "0.0.0.0/0"
}

variable "home_net" {
  description = "Home network"
  default     = "24.80.22.0/24"
}

variable "bcit_net" {
  description = "BCIT network"
  default     = "142.232.0.0/16"
}

variable "ami_id" {
  description = "AMI ID"
  default     = "ami-04203cad30ceb4a0c"
}

variable "ssh_key_name" {
  description = "AWS SSH key name"
  default     = "acit_4640"
}

provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "a02_vpc" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  tags = {
    Name    = "a02_vpc"
    Project = var.project_name
  }
}

resource "aws_subnet" "a02_priv_subnet" {
  vpc_id                  = aws_vpc.a02_vpc.id
  cidr_block              = var.priv_subnet_cidr
  availability_zone       = var.aws_az
  map_public_ip_on_launch = true
  tags = {
    Name    = "a02_priv_subnet"
    Project = var.project_name
  }
}

resource "aws_subnet" "a02_pub_subnet" {
  vpc_id                  = aws_vpc.a02_vpc.id
  cidr_block              = var.pub_subnet_cidr
  availability_zone       = var.aws_az
  map_public_ip_on_launch = true
  tags = {
    Name    = "a02_pub_subnet"
    Project = var.project_name
  }
}

resource "aws_internet_gateway" "a02_gw" {
  vpc_id = aws_vpc.a02_vpc.id
  tags = {
    Name    = "a02_gw"
    Project = var.project_name
  }
}

resource "aws_route_table" "a02_rt" {
  vpc_id = aws_vpc.a02_vpc.id

  route {
    cidr_block = var.default_route
    gateway_id = aws_internet_gateway.a02_gw.id
  }

  tags = {
    Name    = "a02_rt"
    Project = var.project_name
  }
}

resource "aws_route_table_association" "a02_priv_rt_assoc" {
  subnet_id      = aws_subnet.a02_priv_subnet.id
  route_table_id = aws_route_table.a02_rt.id
}

resource "aws_route_table_association" "a02_pub_rt_assoc" {
  subnet_id      = aws_subnet.a02_pub_subnet.id
  route_table_id = aws_route_table.a02_rt.id
}

resource "aws_security_group" "a02_priv_sg" {
  name        = "a02_priv_sg"
  description = "Allow SSH access to EC2 from home and BCIT and all traffic from pub_sg"
  vpc_id      = aws_vpc.a02_vpc.id
}

resource "aws_security_group" "a02_pub_sg" {
  name        = "a02_pub_sg"
  description = "Allow HTTP and SSH access to EC2 from home and BCIT and all traffic from priv_sg"
  vpc_id      = aws_vpc.a02_vpc.id
}

# Private SG egress/ingress rules
resource "aws_vpc_security_group_egress_rule" "priv_egress_rule" {
  security_group_id = aws_security_group.a02_priv_sg.id
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
  tags = {
    Name    = "priv_egress_rule"
    Project = var.project_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "priv_ssh_home_rule" {
  security_group_id = aws_security_group.a02_priv_sg.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = var.home_net
  tags = {
    Name    = "priv_ssh_home_rule"
    Project = var.project_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "priv_ssh_bcit_rule" {
  security_group_id = aws_security_group.a02_priv_sg.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = var.bcit_net
  tags = {
    Name    = "priv_ssh_bcit_rule"
    Project = var.project_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "priv_all_pub_sg_rule" {
  security_group_id = aws_security_group.a02_priv_sg.id
  ip_protocol       = -1
  cidr_ipv4         = var.pub_subnet_cidr
  tags = {
    Name    = "priv_all_pub_sg_rule"
    Project = var.project_name
  }
}

# Public SG egress/ingress rules
resource "aws_vpc_security_group_egress_rule" "pub_egress_rule" {
  security_group_id = aws_security_group.a02_pub_sg.id
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
  tags = {
    Name    = "pub_egress_rule"
    Project = var.project_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "pub_ssh_home_rule" {
  security_group_id = aws_security_group.a02_pub_sg.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = var.home_net
  tags = {
    Name    = "pub_ssh_home_rule"
    Project = var.project_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "pub_ssh_bcit_rule" {
  security_group_id = aws_security_group.a02_pub_sg.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = var.bcit_net
  tags = {
    Name    = "pub_ssh_bcit_rule"
    Project = var.project_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "pub_http_rule" {
  security_group_id = aws_security_group.a02_pub_sg.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
  tags = {
    Name    = "pub_http_rule"
    Project = var.project_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "pub_https_rule" {
  security_group_id = aws_security_group.a02_pub_sg.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
  tags = {
    Name    = "pub_https_rule"
    Project = var.project_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "all_priv_sg_rule" {
  security_group_id = aws_security_group.a02_priv_sg.id
  ip_protocol       = -1
  cidr_ipv4         = var.priv_subnet_cidr
  tags = {
    Name    = "pub_all_priv_sg_rule"
    Project = var.project_name
  }
}
