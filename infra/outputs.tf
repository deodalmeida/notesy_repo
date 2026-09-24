output "app_url" {
  description = "Public URL of the Notesy app."
  value       = "http://${aws_lb.main.dns_name}"
}

output "ecs_cluster_name" {
  description = "ECS cluster name (ECS_CLUSTER in the pipeline)."
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "ECS service name (ECS_SERVICE in the pipeline)."
  value       = aws_ecs_service.app.name
}

output "ecs_task_definition_family" {
  description = "Task definition family (ECS_TASK_DEFINITION in the pipeline)."
  value       = aws_ecs_task_definition.app.family
}

output "ecs_container_name" {
  description = "Container name inside the task definition (CONTAINER_NAME in the pipeline)."
  value       = var.app_name
}

output "ecr_repository_url" {
  description = "ECR repository the task pulls from."
  value       = data.aws_ecr_repository.app.repository_url
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for app logs."
  value       = aws_cloudwatch_log_group.app.name
}

output "github_deploy_policy_arn" {
  description = "Attach this to the GitHub OIDC role if github_deploy_role_name was not set."
  value       = aws_iam_policy.github_deploy.arn
}

output "rds_endpoint" {
  description = "Postgres endpoint (private)."
  value       = aws_db_instance.main.address
}
