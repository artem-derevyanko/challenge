output "NEXT_DOCKER_REGISTRY" {
  value = aws_ecr_repository.app.repository_url
}

output "HASURA_GRAPHQL_DATABASE_URL" {
  value = "postgres://${var.db_username}:${var.db_password}@${aws_db_instance.app.endpoint}/${var.db_name}"
  sensitive = true
}

output "HASURA_GRAPHQL_ENDPOINT" {
  value = "http://${aws_lb.default.dns_name}:${var.hasura_port}"
}

output "HASURA_GRAPHQL_ACTIONS_HANDLER_WEBHOOK_BASEURL" {
  value = "http://${aws_lb.default.dns_name}"
}

output "HASURA_HOST" {
  value = "http://${aws_lb.default.dns_name}:${var.hasura_port}"
}

output "TEST" {
  value = "123"
  sensitive = true
}