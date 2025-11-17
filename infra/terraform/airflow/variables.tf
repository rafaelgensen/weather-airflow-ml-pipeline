variable "region" {
  type    = string
}

variable "project_id" {
  type = string
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
  type = string
}

variable "ecs_task_role" {
  type = string
}
