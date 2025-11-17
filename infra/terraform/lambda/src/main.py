import json
import boto3
import urllib.request
import os
from datetime import datetime


def lambda_handler(event, context):
    project_id = os.environ.get("PROJECT_ID")
    raw_bucket = f"raw-weather-{project_id}"

    url = "https://api.open-meteo.com/v1/forecast?latitude=-23.5&longitude=-46.6&hourly=temperature_2m"

    with urllib.request.urlopen(url, timeout=10) as response:
        data = json.loads(response.read().decode())

    ts = datetime.utcnow().isoformat()
    key = f"raw/{ts}.json"

    s3 = boto3.client("s3")
    s3.put_object(
        Bucket=raw_bucket,
        Key=key,
        Body=json.dumps(data)
    )

    return {
        "statusCode": 200,
        "body": json.dumps({"stored": key})
    }