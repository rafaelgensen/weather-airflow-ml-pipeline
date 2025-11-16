variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project_id" {
  type        = string
  description = "AWS Account ID"
}

variable "db_username" {
  type    = string
  default = "airflow"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "airflow_image" {
  type    = string
  default = "public.ecr.aws/apache/airflow:2.9.1-python3.10"
}

variable "databricks_host" {
  type        = string
  description = "Databricks workspace URL"
}

variable "databricks_token" {
  type        = string
  sensitive   = true
}

variable "databricks_node_type" {
  type    = string
  default = "m5a.large"
}
