terraform {
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.region
}

# -------------------------------------------------------------------
# S3
# -------------------------------------------------------------------
module "s3" {
  source         = "./s3"
  project_id = var.project_id
}

# -------------------------------------------------------------------
# IAM
# -------------------------------------------------------------------
module "iam" {
  source     = "./iam"
  region     = var.region
  project_id = var.project_id
}

# -------------------------------------------------------------------
# AIRFLOW
# -------------------------------------------------------------------
module "airflow" {
  source       = "./airflow"
  region       = var.region
  project_id   = var.project_id

  db_username  = var.db_username
  db_password  = var.db_password
  airflow_image = var.airflow_image

  ecs_execution_role = module.iam.ecs_execution_role_arn
  ecs_task_role      = module.iam.airflow_task_role_arn
}

# -------------------------------------------------------------------
# DATABRICKS
# -------------------------------------------------------------------
module "databricks" {
  source = "./databricks"

  databricks_host  = var.databricks_host
  databricks_token = var.databricks_token
  node_type        = var.databricks_node_type

  project_id = var.project_id
}

# -------------------------------------------------------------------
# LAMBDA
# -------------------------------------------------------------------
module "lambda" {
  source = "./lambda"

  region     = var.region
  project_id = var.project_id

  lambda_role_arn = module.iam.lambda_role_arn
}
