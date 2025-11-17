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

# -------------------------------------------------------------------
# LOCALS — NOME DOS BUCKETS PADRÃO
# -------------------------------------------------------------------
locals {
  raw_bucket       = "raw-weather-${var.project_id}"
  processed_bucket = "processed-weather-${var.project_id}"
  ml_output_bucket = "ml-output-weather-${var.project_id}"
}

# -------------------------------------------------------------------
# ECS EXECUTION ROLE (TASK EXECUTION)
# -------------------------------------------------------------------
data "aws_iam_policy_document" "ecs_tasks_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ecs_execution_role" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# -------------------------------------------------------------------
# ECS TASK ROLE (AIRFLOW)
# -------------------------------------------------------------------
resource "aws_iam_role" "airflow_task_role" {
  name               = "airflow-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
}

data "aws_iam_policy_document" "airflow_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${local.raw_bucket}",
      "arn:aws:s3:::${local.raw_bucket}/*",
      "arn:aws:s3:::${local.processed_bucket}",
      "arn:aws:s3:::${local.processed_bucket}/*",
      "arn:aws:s3:::${local.ml_output_bucket}",
      "arn:aws:s3:::${local.ml_output_bucket}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "execute-api:Invoke",
      "execute-api:ManageConnections"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "airflow_policy" {
  name        = "airflow-access-policy"
  policy      = data.aws_iam_policy_document.airflow_permissions.json
}

resource "aws_iam_role_policy_attachment" "airflow_task_role_attach" {
  role       = aws_iam_role.airflow_task_role.name
  policy_arn = aws_iam_policy.airflow_policy.arn
}

# -------------------------------------------------------------------
# LAMBDA ROLE
# -------------------------------------------------------------------
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "lambda-ingest-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "lambda_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${local.raw_bucket}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name   = "lambda-ingest-policy"
  policy = data.aws_iam_policy_document.lambda_permissions.json
}

resource "aws_iam_role_policy_attachment" "lambda_role_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# -------------------------------------------------------------------
# DATABRICKS INSTANCE PROFILE
# -------------------------------------------------------------------
data "aws_iam_policy_document" "databricks_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [var.project_id]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "databricks_instance_profile" {
  name               = "databricks-instance-profile"
  assume_role_policy = data.aws_iam_policy_document.databricks_assume.json
}

data "aws_iam_policy_document" "databricks_s3" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${local.raw_bucket}",
      "arn:aws:s3:::${local.raw_bucket}/*",
      "arn:aws:s3:::${local.processed_bucket}",
      "arn:aws:s3:::${local.processed_bucket}/*",
      "arn:aws:s3:::${local.ml_output_bucket}",
      "arn:aws:s3:::${local.ml_output_bucket}/*"
    ]
  }
}

resource "aws_iam_policy" "databricks_s3_policy" {
  name   = "databricks-s3-access"
  policy = data.aws_iam_policy_document.databricks_s3.json
}

resource "aws_iam_role_policy_attachment" "databricks_profile_attach" {
  role       = aws_iam_role.databricks_instance_profile.name
  policy_arn = aws_iam_policy.databricks_s3_policy.arn
}
