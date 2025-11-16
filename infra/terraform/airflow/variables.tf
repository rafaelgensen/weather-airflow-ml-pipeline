variable "region" {
  type    = string
}

variable "project_id" {
  type        = string
  description = "AWS Account ID"
}

variable "airflow_image" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_name" {
  type    = string
  default = "airflow"
}

variable "ecs_execution_role" {
  type        = string
  description = "IAM execution role ARN for ECS tasks"
}

variable "ecs_task_role" {
  type        = string
  description = "IAM task role ARN for ECS tasks"
}

variable "databricks_host" {
  type        = string
  description = "Databricks workspace URL (full, e.g. https://abc.cloud.databricks.com)"
}

variable "databricks_token" {
  type      = string
  sensitive = true
}

variable "databricks_transform_job_id" {
  type = string
}

variable "databricks_train_job_id" {
  type = string
}

variable "databricks_infer_job_id" {
  type = string
}
