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
# VPC
# -------------------------------
resource "aws_vpc" "airflow" {
  cidr_block = "10.10.0.0/16"
}

resource "aws_internet_gateway" "airflow" {
  vpc_id = aws_vpc.airflow.id
}

resource "aws_subnet" "subnet_a" {
  vpc_id                  = aws_vpc.airflow.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet_b" {
  vpc_id                  = aws_vpc.airflow.id
  cidr_block              = "10.10.2.0/24"
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.airflow.id
}

resource "aws_route" "igw_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.airflow.id
}

resource "aws_route_table_association" "subnet_a_assoc" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "subnet_b_assoc" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.public.id
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
  name        = "airflow-ecs-sg"
  description = "SG for ECS Airflow tasks"
  vpc_id      = aws_vpc.airflow.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "airflow_db" {
  name        = "airflow-db-sg"
  description = "SG for RDS"
  vpc_id      = aws_vpc.airflow.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.airflow_ecs.id]
  }
}

# -------------------------------
# RDS
# -------------------------------
resource "aws_db_subnet_group" "default_subnets" {
  name       = "airflow-rds-subnets-2"
  subnet_ids = [
    aws_subnet.subnet_a.id,
    aws_subnet.subnet_b.id
  ]
}

resource "aws_db_instance" "airflow" {
  identifier             = "airflow-db"
  engine                 = "postgres"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_subnet_group_name   = aws_db_subnet_group.default_subnets.name
  vpc_security_group_ids = [aws_security_group.airflow_db.id]

  username = var.db_username
  password = var.db_password

  skip_final_snapshot = true
  publicly_accessible = false
}

# -------------------------------
# ECS CLUSTER
# -------------------------------
resource "aws_ecs_cluster" "airflow" {
  name = "airflow-cluster"
}

# -------------------------------
# TASK DEFINITION
# -------------------------------
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
    }
  ])
}

# -------------------------------
# ECS SERVICE
# -------------------------------
resource "aws_ecs_service" "airflow" {
  name            = "airflow-service"
  cluster         = aws_ecs_cluster.airflow.id
  task_definition = aws_ecs_task_definition.airflow.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets = [
      aws_subnet.subnet_a.id,
      aws_subnet.subnet_b.id
    ]
    security_groups = [aws_security_group.airflow_ecs.id]
  }

  depends_on = [
    aws_db_instance.airflow
  ]
}
