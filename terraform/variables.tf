variable "project_name" {
  type    = string
  default = "intervue"
}
variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "aws_az" {
  type    = string
  default = "us-east-1a"
}
variable "subnet_a_az" {
  type    = string
  default = "us-east-1a"
}
variable "subnet_b_az" {
  type    = string
  default = "us-east-1b"
}
variable "postgres_instance_class" {
  type    = string
  default = "db.t3.micro"
}
variable "postgres_storage_allocation" {
  type    = number
  default = 10
}
variable "postgres_storage_type" {
  type    = string
  default = "gp2"
}
variable "postgres_db_name" {
  type    = string
  default = "appdb"
}
variable "postgres_password" {
  type      = string
  sensitive = true
}
variable "postgres_username" {
  type    = string
  default = "intervue_psql"
}
variable "bastion_instance_type" {
  type    = string
  default = "t2.micro"
}
variable "psql_sshkey" {
  type      = string
  sensitive = true
}