# airflow module - main.tf
# This module expects to receive:
# - var.region
# - var.project_id
# - var.airflow_image
# - var.db_username, var.db_password, var.db_name
# - var.ecs_execution_role, var.ecs_task_role (ARNs)
# - var.databricks_host, var.databricks_token
# - var.databricks_transform_job_id, var.databricks_train_job_id, var.databricks_infer_job_id

locals {
  ecs_execution_role_arn = var.ecs_execution_role
  ecs_task_role_arn      = var.ecs_task_role
  # remove https:// if present for AIRFLOW_CONN
  databricks_host_clean  = replace(var.databricks_host, "https://", "")
  databricks_conn_uri    = "databricks://token:${var.databricks_token}@${local.databricks_host_clean}"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_cloudwatch_log_group" "airflow" {
  name              = "/ecs/airflow"
  retention_in_days = 7
}

resource "aws_security_group" "airflow_ecs" {
  name        = "airflow-ecs-sg"
  description = "SG for ECS Airflow tasks"
  vpc_id      = data.aws_vpc.default.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "airflow_db" {
  name        = "airflow-db-sg"
  description = "SG for RDS Postgres"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.airflow_ecs.id]
  }
}

resource "aws_db_subnet_group" "default_subnets" {
  name       = "airflow-default-subnets"
  subnet_ids = data.aws_subnets.default.ids
}

resource "aws_db_instance" "airflow" {
  identifier              = "airflow-db"
  engine                  = "postgres"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  db_subnet_group_name    = aws_db_subnet_group.default_subnets.name
  vpc_security_group_ids  = [aws_security_group.airflow_db.id]

  username = var.db_username
  password = var.db_password

  skip_final_snapshot = true
  publicly_accessible = false
}

resource "aws_ecs_cluster" "airflow" {
  name = "airflow-cluster"
}

resource "aws_ecs_task_definition" "airflow" {
  family                   = "airflow"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"

  execution_role_arn = local.ecs_execution_role_arn
  task_role_arn      = local.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name  = "airflow"
      image = var.airflow_image

      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]

      environment = [
        { name = "AIRFLOW__CORE__EXECUTOR", value = "LocalExecutor" },
        { name = "AIRFLOW__CORE__SQL_ALCHEMY_CONN", value = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.airflow.address}:5432/${var.db_name}" },
        { name = "PROJECT_ID", value = var.project_id },
        { name = "DATABRICKS_TRANSFORM_JOB_ID", value = var.databricks_transform_job_id },
        { name = "DATABRICKS_TRAIN_JOB_ID", value = var.databricks_train_job_id },
        { name = "DATABRICKS_INFER_JOB_ID", value = var.databricks_infer_job_id },
        { name = "AIRFLOW_CONN_DATABRICKS_DEFAULT", value = local.databricks_conn_uri }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.airflow.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "airflow"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "airflow" {
  name            = "airflow-service"
  cluster         = aws_ecs_cluster.airflow.id
  task_definition = aws_ecs_task_definition.airflow.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = data.aws_subnets.default.ids
    security_groups = [aws_security_group.airflow_ecs.id]
  }

  depends_on = [
    aws_db_instance.airflow
  ]
}

output "airflow_rds_endpoint" {
  value = aws_db_instance.airflow.address
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.airflow.name
}

output "airflow_service_name" {
  value = aws_ecs_service.airflow.name
}
