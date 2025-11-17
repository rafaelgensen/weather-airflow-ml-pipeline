output "ecs_execution_role_arn" {
  value = aws_iam_role.ecs_execution_role.arn
}

output "airflow_task_role_arn" {
  value = aws_iam_role.airflow_task_role.arn
}

output "lambda_role_arn" {
  value = aws_iam_role.lambda_role.arn
}

output "databricks_instance_profile_arn" {
  value = aws_iam_role.databricks_instance_profile.arn
}
