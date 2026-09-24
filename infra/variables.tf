variable "app_name" {
  description = "Application name, used as the prefix for every resource."
  type        = string
  default     = "notesy"
}

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.20.0.0/16"
}

# ---- Container image ----

variable "ecr_repository_name" {
  description = "Existing ECR repository the CI pipeline pushes to."
  type        = string
  default     = "notesy"
}

variable "image_tag" {
  description = "Image tag to deploy (commit SHA from CI, or latest)."
  type        = string
  default     = "latest"
}

# ---- Task sizing ----

variable "container_port" {
  description = "Port gunicorn listens on inside the container."
  type        = number
  default     = 8000
}

variable "task_cpu" {
  description = "Fargate task CPU units (256 = 0.25 vCPU)."
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Fargate task memory in MiB."
  type        = number
  default     = 1024
}

variable "desired_count" {
  description = "Number of running tasks."
  type        = number
  default     = 1
}

variable "gunicorn_workers" {
  description = "Number of gunicorn worker processes per task."
  type        = number
  default     = 3
}

# ---- Django config ----

variable "django_allowed_hosts" {
  description = "Comma-separated DJANGO_ALLOWED_HOSTS. Empty = the ALB DNS name. The task's private IP (used by ALB health checks) is added by the app at start-up."
  type        = string
  default     = ""
}

variable "run_seed" {
  description = "Run manage.py seed on container start (creates the demo/demo user)."
  type        = bool
  default     = false
}

variable "django_csrf_trusted_origins" {
  description = "Comma-separated DJANGO_CSRF_TRUSTED_ORIGINS, e.g. https://notesy.example.com once HTTPS is set up."
  type        = string
  default     = ""
}

variable "summarizer_url" {
  description = "SUMMARIZER_URL passed to the app."
  type        = string
  default     = ""
}

variable "summarizer_api_key" {
  description = "SUMMARIZER_API_KEY, stored in Secrets Manager. Leave empty if unused."
  type        = string
  default     = ""
  sensitive   = true
}

# ---- Database ----

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "RDS storage in GiB."
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Postgres database name."
  type        = string
  default     = "notesy"
}

variable "db_username" {
  description = "Postgres master username."
  type        = string
  default     = "notesy"
}

variable "db_deletion_protection" {
  description = "Protect the RDS instance from deletion (and take a final snapshot). Set true for production."
  type        = bool
  default     = false
}

# ---- CI/CD ----

variable "github_deploy_role_name" {
  description = "Name of the existing GitHub OIDC IAM role (the one behind AWS_ECR_DEPLOY_ROLE_ARN). If set, ECS deploy permissions are attached to it."
  type        = string
  default     = ""
}

variable "log_retention_days" {
  description = "CloudWatch log retention for the app logs."
  type        = number
  default     = 14
}
