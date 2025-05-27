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

data "aws_subnet_ids" "default_subnet" {
  vpc_id = data.aws_vpc.default_vpc.id
}
resource "aws_security_group" "db" {
  name = "db-security-group"
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
    publicly_accessible       = true
    skip_final_snapshot       = false
    final_snapshot_identifier = "${var.project_name}-postgres-${var.postgres_db_name}-final-snapshot"
}
