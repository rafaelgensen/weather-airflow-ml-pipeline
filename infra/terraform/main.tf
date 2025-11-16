terraform {
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.region
}

# -------------------------------------------------------------------
# MODULE: S3
# -------------------------------------------------------------------
module "s3" {
  source     = "./s3"
  project_id = var.project_id
}

# -------------------------------------------------------------------
# MODULE: IAM
# -------------------------------------------------------------------
module "iam" {
  source     = "./iam"
  region     = var.region
  project_id = var.project_id

  depends_on = [module.s3]
}

# -------------------------------------------------------------------
# MODULE: DATABRICKS (create notebooks + jobs first)
# -------------------------------------------------------------------
module "databricks" {
  source            = "./databricks"

  databricks_host  = var.databricks_host
  databricks_token = var.databricks_token

  node_type  = var.databricks_node_type
  project_id = var.project_id

  depends_on = [
    module.iam,
    module.s3
  ]
}

# -------------------------------------------------------------------
# MODULE: AIRFLOW
# -------------------------------------------------------------------
module "airflow" {
  source     = "./airflow"
  region     = var.region
  project_id = var.project_id

  db_username   = var.db_username
  db_password   = var.db_password
  airflow_image = var.airflow_image

  ecs_execution_role = module.iam.ecs_execution_role_arn
  ecs_task_role      = module.iam.airflow_task_role_arn

  # Databricks connection + job ids for DAG env
  databricks_host              = var.databricks_host
  databricks_token             = var.databricks_token
  databricks_transform_job_id  = module.databricks.databricks_transform_job_id
  databricks_train_job_id      = module.databricks.databricks_train_job_id
  databricks_infer_job_id      = module.databricks.databricks_infer_job_id

  depends_on = [
    module.iam,
    module.s3,
    module.databricks
  ]
}

# -------------------------------------------------------------------
# MODULE: LAMBDA
# -------------------------------------------------------------------
module "lambda" {
  source          = "./lambda"
  region          = var.region
  project_id      = var.project_id
  lambda_role_arn = module.iam.lambda_role_arn

  depends_on = [
    module.iam,
    module.s3
  ]
}
