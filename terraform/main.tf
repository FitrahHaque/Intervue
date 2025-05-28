terraform {
  cloud { 
    organization = "intervue" 
    workspaces { 
      name = "app-database"
    }
  }
  required_providers {
    aws = {
        source  = "hashicorp/aws"
        version = "~> 5.0"
    }
  }
}
provider "aws" {
  region = var.aws_region
}
data "aws_vpc" "default_vpc" {
  default = true
}
# data "aws_subnets" "private" {
#   filter {
#     name = "vpc-id"
#     values = [data.aws_vpc.default_vpc.id]
#   }
# }
data "aws_availability_zones" "available" {
  state = "available"
}
resource "aws_subnet" "subnet_a" {
  vpc_id = data.aws_vpc.default_vpc.id
  cidr_block = cidrsubnet(data.aws_vpc.default_vpc.cidr_block, 8, 1)
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "${var.project_name}-db-subnet-a"
  }
}
resource "aws_subnet" "subnet_b" {
  vpc_id = data.aws_vpc.default_vpc.id
  cidr_block = cidrsubnet(data.aws_vpc.default_vpc.cidr_block, 8, 2)
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "${var.project_name}-db-subnet-b"
  }
}
resource "aws_db_subnet_group" "postgres" {
  name = "${var.project_name}-db-subnets"
  subnet_ids = [
    aws_subnet.subnet_a.id,
    aws_subnet.subnet_b.id,
  ]
}
resource "aws_security_group" "db" {
  name = "db-security-group"
  vpc_id = data.aws_vpc.default_vpc.id
}
resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.db.id
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}
# PostgreSQL (RDS)
resource "aws_db_instance" "postgres" {
    identifier_prefix         = "${var.project_name}-postgres-"
    instance_class            = var.postgres_instance_class
    engine                    = "postgres"
    allocated_storage         = 10
    db_name                   = var.postgres_db_name
    username                  = var.postgres_username
    password                  = var.postgres_password
    vpc_security_group_ids    = [aws_security_group.db.id]
    publicly_accessible       = true
    db_subnet_group_name      = aws_db_subnet_group.postgres.name
    multi_az                  = true
    skip_final_snapshot       = true
}