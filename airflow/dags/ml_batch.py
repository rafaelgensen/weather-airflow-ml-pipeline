from airflow import DAG
from airflow.providers.databricks.operators.databricks import DatabricksRunNowOperator
from datetime import datetime, timedelta
import os

# Renomeado para usar o env var que o Terraform injeta: DATABRICKS_TRAIN_JOB_ID
JOB_ID = os.environ.get("DATABRICKS_TRAIN_JOB_ID")

default_args = {
    "owner": "airflow",
    "retries": 1,
    "retry_delay": timedelta(minutes=3)
}

with DAG(
    dag_id="ml_batch_weather",
    start_date=datetime(2024, 1, 1),
    schedule_interval=None,
    catchup=False,
    default_args=default_args,
) as dag:

    run_ml = DatabricksRunNowOperator(
        task_id="run_ml_job",
        databricks_conn_id="databricks_default",
        job_id=JOB_ID
    )