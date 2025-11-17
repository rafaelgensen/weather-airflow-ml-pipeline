from pyspark.sql import SparkSession
from pyspark.sql import functions as F
from pyspark.ml.feature import VectorAssembler
from pyspark.ml.regression import LinearRegression
import datetime

spark = SparkSession.builder.appName("weather-ml-train").getOrCreate()

project_id = dbutils.widgets.get("project_id")
processed_bucket = f"processed-weather-{project_id}"
model_bucket = f"ml-output-weather-{project_id}"

# ---------------------------------------------------------------
# Load processed data
# ---------------------------------------------------------------
path = f"s3://{processed_bucket}/weather/"
df = spark.read.parquet(path)

# Create features
df = df.withColumn("hour", F.hour("timestamp"))
df = df.withColumn("temp_label", F.col("temperature"))

assembler = VectorAssembler(
    inputCols=["hour"],
    outputCol="features"
)

df_feat = assembler.transform(df)

# ---------------------------------------------------------------
# Train model
# ---------------------------------------------------------------
lr = LinearRegression(
    labelCol="temp_label",
    featuresCol="features"
)

model = lr.fit(df_feat)

# ---------------------------------------------------------------
# Save model
# ---------------------------------------------------------------
model_path = f"s3://{model_bucket}/model/"
model.write().overwrite().save(model_path)

print("Model trained and saved:", model_path)
