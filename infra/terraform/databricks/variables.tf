variable "databricks_host" {
  type = string
}

variable "databricks_token" {
  type = string
}

variable "node_type" {
  type    = string
  default = "m5a.large"
}

variable "project_id" {
  type = string
}
