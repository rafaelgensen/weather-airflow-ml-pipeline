from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta
import requests
import boto3
import json
import os

RAW_BUCKET = f"raw-weather-{os.environ.get('PROJECT_ID')}"

def extract_weather(**context):
    url = "https://api.open-meteo.com/v1/forecast?latitude=-23.5&longitude=-46.6&hourly=temperature_2m"
    r = requests.get(url, timeout=10)
    r.raise_for_status()

    data = r.json()
    key = f"raw/{datetime.utcnow().isoformat()}.json"

    s3 = boto3.client("s3")
    s3.put_object(
        Bucket=RAW_BUCKET,
        Key=key,
        Body=json.dumps(data)
    )

default_args = {
    "owner": "airflow",
    "retries": 1,
    "retry_delay": timedelta(minutes=2)
}

with DAG(
    dag_id="extract_api_weather",
    start_date=datetime(2024, 1, 1),
    schedule_interval="@hourly",
    catchup=False,
    default_args=default_args,
) as dag:

    extract = PythonOperator(
        task_id="extract_weather_api",
        python_callable=extract_weather
    )
