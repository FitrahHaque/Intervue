output "postgres_endpoint" {
  value = aws_db_instance.postgres.endpoint
}
output "bastion_psql_public_ip" {
  value = aws_instance.bastion_psql.public_ip
}