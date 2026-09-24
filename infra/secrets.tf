# App secrets live in Secrets Manager and are injected into the container by
# ECS at start-up, so they never appear in the task definition or the image.

resource "random_password" "django_secret_key" {
  length  = 50
  special = true
}

resource "aws_secretsmanager_secret" "django_secret_key" {
  name                    = "${var.app_name}/DJANGO_SECRET_KEY"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "django_secret_key" {
  secret_id     = aws_secretsmanager_secret.django_secret_key.id
  secret_string = random_password.django_secret_key.result
}

resource "aws_secretsmanager_secret" "database_url" {
  name                    = "${var.app_name}/DATABASE_URL"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "database_url" {
  secret_id     = aws_secretsmanager_secret.database_url.id
  secret_string = "postgres://${var.db_username}:${random_password.db.result}@${aws_db_instance.main.address}:${aws_db_instance.main.port}/${var.db_name}"
}

resource "aws_secretsmanager_secret" "summarizer_api_key" {
  name                    = "${var.app_name}/SUMMARIZER_API_KEY"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "summarizer_api_key" {
  secret_id     = aws_secretsmanager_secret.summarizer_api_key.id
  secret_string = var.summarizer_api_key == "" ? "unset" : var.summarizer_api_key
}

locals {
  app_secret_arns = [
    aws_secretsmanager_secret.django_secret_key.arn,
    aws_secretsmanager_secret.database_url.arn,
    aws_secretsmanager_secret.summarizer_api_key.arn,
  ]
}
