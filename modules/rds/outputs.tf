output "db_instance_endpoint" {
  description = "RDS endpoint (якщо використовується стандартний RDS)"
  value       = try(aws_db_instance.standard[0].endpoint, null)
}

output "db_instance_port" {
  description = "RDS порт (якщо використовується стандартний RDS)"
  value       = try(aws_db_instance.standard[0].port, null)
}

output "db_instance_arn" {
  description = "RDS ARN (якщо використовується стандартний RDS)"
  value       = try(aws_db_instance.standard[0].arn, null)
}

output "aurora_cluster_endpoint" {
  description = "Aurora writer endpoint (якщо використовується Aurora)"
  value       = try(aws_rds_cluster.aurora[0].endpoint, null)
}

output "aurora_reader_endpoint" {
  description = "Aurora reader endpoint (якщо використовується Aurora)"
  value       = try(aws_rds_cluster.aurora[0].reader_endpoint, null)
}

output "aurora_cluster_arn" {
  description = "Aurora cluster ARN (якщо використовується Aurora)"
  value       = try(aws_rds_cluster.aurora[0].arn, null)
}

output "db_name" {
  description = "Ім'я бази даних"
  value       = var.db_name
}

output "username" {
  description = "Користувач БД"
  value       = var.username
}

output "password" {
  description = "Пароль БД (sensitive)"
  value       = var.password
  sensitive   = true
}
