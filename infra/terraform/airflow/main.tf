terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

locals {
  ecs_execution_role_arn = var.ecs_execution_role
  ecs_task_role_arn      = var.ecs_task_role
}

# -------------------------------
# DEFAULT VPC
# -------------------------------
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# -------------------------------
# LOG GROUP
# -------------------------------
resource "aws_cloudwatch_log_group" "airflow" {
  name              = "/ecs/airflow"
  retention_in_days = 7
}

# -------------------------------
# SECURITY GROUPS
# -------------------------------
resource "aws_security_group" "airflow_ecs" {
  name        = "airflow-ecs-sg-2"
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
  name        = "airflow-db-sg-2"
  description = "SG for RDS"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.airflow_ecs.id]
  }
}

# -------------------------------
# RDS — NOME TOTALMENTE NOVO
# -------------------------------
resource "aws_db_subnet_group" "default_subnets" {
  name       = "airflow-subnet-group-3"
  subnet_ids = data.aws_subnets.default.ids
}

resource "aws_db_instance" "airflow" {
  identifier             = "airflow-db-3"
  engine                 = "postgres"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_subnet_group_name   = aws_db_subnet_group.default_subnets.name
  vpc_security_group_ids = [aws_security_group.airflow_db.id]

  username = var.db_username
  password = var.db_password
  db_name  = var.db_name

  skip_final_snapshot = true
  publicly_accessible = false
}

# -------------------------------
# ECS CLUSTER
# -------------------------------
resource "aws_ecs_cluster" "airflow" {
  name = "airflow-cluster-2"
}

# -------------------------------
# ECS TASK DEFINITION
# -------------------------------
resource "aws_ecs_task_definition" "airflow" {
  family                   = "airflow-2"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"

  execution_role_arn = local.ecs_execution_role_arn
  task_role_arn      = local.ecs_task_role_arn

  container_definitions = jsonencode([{
    name  = "airflow"
    image = var.airflow_image

    portMappings = [{
      containerPort = 8080
      hostPort      = 8080
    }]

    environment = [
      {
        name  = "AIRFLOW__CORE__EXECUTOR"
        value = "LocalExecutor"
      },
      {
        name  = "AIRFLOW__CORE__SQL_ALCHEMY_CONN"
        value = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.airflow.address}:5432/${var.db_name}"
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.airflow.name
        awslogs-region        = var.region
        awslogs-stream-prefix = "airflow"
      }
    }
  }])
}

# -------------------------------
# ECS SERVICE
# -------------------------------
resource "aws_ecs_service" "airflow" {
  name            = "airflow-service-2"
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
