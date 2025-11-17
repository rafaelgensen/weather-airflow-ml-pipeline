output "databricks_transform_job_id" {
  value = databricks_job.transform_job.id
}

output "databricks_train_job_id" {
  value = databricks_job.train_job.id
}

output "databricks_infer_job_id" {
  value = databricks_job.infer_job.id
}
