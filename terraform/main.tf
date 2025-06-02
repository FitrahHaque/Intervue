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
resource "aws_s3_bucket" "s3_bucket" {
  bucket = "${var.project_name}-s3-bucket"
  tags = {
    Name        = "${var.project_name}-s3-bucket"
    Environment = terraform.workspace
  }
}
resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.s3_bucket.id
  versioning_configuration {
    status = "Disabled"
  }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_sse" {
  bucket = aws_s3_bucket.s3_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}
resource "aws_subnet" "subnet_a" {
  vpc_id            = data.aws_vpc.default_vpc.id
  cidr_block        = cidrsubnet(data.aws_vpc.default_vpc.cidr_block, 8, 1)
  availability_zone = var.subnet_a_az
  tags = {
    Name = "${var.project_name}-db-subnet-a"
  }
}
resource "aws_subnet" "subnet_b" {
  vpc_id            = data.aws_vpc.default_vpc.id
  cidr_block        = cidrsubnet(data.aws_vpc.default_vpc.cidr_block, 8, 2)
  availability_zone = var.subnet_b_az
  tags = {
    Name = "${var.project_name}-db-subnet-b"
  }
}
resource "aws_subnet" "subnet_public" {
  vpc_id                  = data.aws_vpc.default_vpc.id
  cidr_block              = cidrsubnet(data.aws_vpc.default_vpc.cidr_block, 8, 3)
  availability_zone       = var.subnet_a_az
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}
resource "aws_db_subnet_group" "subnets" {
  name = "${var.project_name}-db-subnets"
  subnet_ids = [
    aws_subnet.subnet_a.id,
    aws_subnet.subnet_b.id,
  ]
}
resource "aws_security_group" "bastion_host" {
  name        = "${var.project_name}-ec2"
  description = "Allow SSH only from user IP"
  vpc_id      = data.aws_vpc.default_vpc.id
}
resource "aws_vpc_security_group_ingress_rule" "bastion_host" {
  security_group_id = aws_security_group.bastion_host.id
  description       = "Allow SSH all users"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}
resource "aws_vpc_security_group_egress_rule" "bastion_host" {
  security_group_id = aws_security_group.bastion_host.id
  description       = "Allow all outbound"
  from_port         = 0
  to_port           = 0
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
resource "aws_security_group" "rds_psql" {
  name        = "${var.project_name}-psql"
  description = "Allow PosgreSQL only from EC2 bastion"
  vpc_id      = data.aws_vpc.default_vpc.id
}
resource "aws_vpc_security_group_ingress_rule" "rds_psql" {
  security_group_id            = aws_security_group.rds_psql.id
  description                  = "Allow Postgres from bastion"
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.bastion_host.id
}
resource "aws_vpc_security_group_egress_rule" "rds_psql" {
  security_group_id = aws_security_group.rds_psql.id
  description       = "Allow all outbound"
  ip_protocol       = "-1"
  from_port         = 0
  to_port           = 0
  cidr_ipv4         = "0.0.0.0/0"
}
resource "aws_key_pair" "bastion" {
  key_name   = "${var.project_name}-bastion-key"
  public_key = var.psql_sshkey
}
resource "aws_instance" "bastion_psql" {
  ami                         = "ami-011899242bb902164" # Ubuntu 20.04 LTS // us-east-1
  instance_type               = var.bastion_instance_type
  subnet_id                   = aws_subnet.subnet_public.id
  key_name                    = aws_key_pair.bastion.key_name
  vpc_security_group_ids      = [aws_security_group.bastion_host.id]
  associate_public_ip_address = true
  tags = {
    Name = "${var.project_name}-bastion-psql"
  }
}
resource "aws_db_instance" "postgres" {
  identifier             = "${var.project_name}-postgres"
  instance_class         = var.postgres_instance_class
  engine                 = "postgres"
  allocated_storage      = var.postgres_storage_allocation
  storage_type           = var.postgres_storage_type
  db_name                = var.postgres_db_name
  username               = var.postgres_username
  password               = var.postgres_password
  vpc_security_group_ids = [aws_security_group.rds_psql.id]
  db_subnet_group_name   = aws_db_subnet_group.subnets.name
  skip_final_snapshot    = true
  availability_zone      = var.subnet_a_az
  publicly_accessible    = false
  multi_az               = false
}