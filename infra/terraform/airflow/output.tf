output "airflow_rds_endpoint" {
  value = aws_db_instance.airflow.address
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.airflow.name
}

output "airflow_service_name" {
  value = aws_ecs_service.airflow.name
}