variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project_id" {
  type = string
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
  type = string
}

variable "databricks_host" {
  type = string
}

variable "databricks_token" {
  type      = string
  sensitive = true
}

variable "databricks_node_type" {
  type    = string
  default = "m5a.large"
}
