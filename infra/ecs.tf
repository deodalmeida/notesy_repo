data "aws_ecr_repository" "app" {
  name = var.ecr_repository_name
}

locals {
  image = "${data.aws_ecr_repository.app.repository_url}:${var.image_tag}"

  allowed_hosts = var.django_allowed_hosts != "" ? var.django_allowed_hosts : aws_lb.main.dns_name

  # Same start-up sequence as docker-compose: migrate (idempotent), optionally
  # seed the demo user, then serve with gunicorn.
  start_command = join(" && ", compact([
    "python manage.py migrate --noinput",
    var.run_seed ? "python manage.py seed" : "",
    "exec gunicorn notesy.wsgi:application --bind 0.0.0.0:${var.container_port} --workers ${var.gunicorn_workers} --access-logfile -",
  ]))
}

resource "aws_ecs_cluster" "main" {
  name = "${var.app_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.app_name}"
  retention_in_days = var.log_retention_days
}

resource "aws_ecs_task_definition" "app" {
  family                   = var.app_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      # The CI pipeline refers to this container by name when it swaps the image.
      name      = var.app_name
      image     = local.image
      essential = true

      command = ["sh", "-c", local.start_command]

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "DJANGO_DEBUG", value = "False" },
        { name = "DJANGO_ALLOWED_HOSTS", value = local.allowed_hosts },
        { name = "DJANGO_CSRF_TRUSTED_ORIGINS", value = var.django_csrf_trusted_origins },
        { name = "SUMMARIZER_URL", value = var.summarizer_url },
      ]

      secrets = [
        { name = "DJANGO_SECRET_KEY", valueFrom = aws_secretsmanager_secret.django_secret_key.arn },
        { name = "DATABASE_URL", valueFrom = aws_secretsmanager_secret.database_url.arn },
        { name = "SUMMARIZER_API_KEY", valueFrom = aws_secretsmanager_secret.summarizer_api_key.arn },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.app.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "web"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "app" {
  name            = "${var.app_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  # Migrations run on start-up, so give the first boot time before health checks count.
  health_check_grace_period_seconds = 120

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  deployment_circuit_breaker {
    enable   = true
    rollback = true # automatically roll back to the last good revision
  }

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true # lets tasks reach ECR/Secrets Manager without a NAT gateway
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = var.app_name
    container_port   = var.container_port
  }

  # After the first apply, the CI pipeline owns which image revision is running
  # (it registers new task definition revisions per commit SHA). Ignoring this
  # stops `terraform apply` from rolling the service back to the Terraform revision.
  lifecycle {
    ignore_changes = [task_definition]
  }

  depends_on = [aws_lb_listener.http]
}
