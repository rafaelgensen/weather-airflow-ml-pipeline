variable "databricks_host" {
  type        = string
  description = "Databricks workspace URL"
}

variable "databricks_token" {
  type        = string
  sensitive   = true
}

variable "node_type" {
  type    = string
  default = "m5a.large"
}

variable "project_id" {
  type        = string
  description = "AWS Account ID for bucket naming"
}
