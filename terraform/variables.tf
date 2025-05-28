variable "project_name" {
  type    = string
  default = "intervue"
}
variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "aws_security_group_db_name" {
  type    = string
  default = "intervue-db-sg"
}
variable "postgres_instance_class" {
  type    = string
  default = "db.t3.micro"
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