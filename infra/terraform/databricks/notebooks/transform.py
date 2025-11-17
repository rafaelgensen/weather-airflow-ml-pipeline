from pyspark.sql import functions as F
from pyspark.sql import SparkSession
import json
import datetime

spark = SparkSession.builder.appName("weather-transform").getOrCreate()

project_id = dbutils.widgets.get("project_id")
raw_bucket = f"raw-weather-{project_id}"
processed_bucket = f"processed-weather-{project_id}"

# ---------------------------------------------------------------
# Read latest raw file
# ---------------------------------------------------------------
raw_path = f"s3://{raw_bucket}/"

df_raw = (
    spark.read.json(raw_path)
    .orderBy(F.input_file_name().desc())
    .limit(1)
)

# ---------------------------------------------------------------
# Explode hourly temperature structure
# ---------------------------------------------------------------
df_exploded = (
    df_raw
    .select(
        F.explode(
            F.arrays_zip(
                F.col("hourly.time"),
                F.col("hourly.temperature_2m")
            )
        ).alias("row")
    )
    .select(
        F.col("row.time").alias("timestamp"),
        F.col("row.temperature_2m").alias("temperature")
    )
)

# ---------------------------------------------------------------
# Write curated/processed
# ---------------------------------------------------------------
output_path = f"s3://{processed_bucket}/weather/"
df_exploded.write.mode("overwrite").parquet(output_path)

print("Transform completed:", output_path)
