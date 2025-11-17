from pyspark.sql import SparkSession
from pyspark.sql import functions as F
from pyspark.ml.feature import VectorAssembler
from pyspark.ml.regression import LinearRegressionModel
import datetime

spark = SparkSession.builder.appName("weather-ml-inference").getOrCreate()

project_id = dbutils.widgets.get("project_id")
model_bucket = f"ml-output-weather-{project_id}"
output_bucket = f"ml-output-weather-{project_id}"

# ---------------------------------------------------------------
# Load model
# ---------------------------------------------------------------
model_path = f"s3://{model_bucket}/model/"
model = LinearRegressionModel.load(model_path)

# ---------------------------------------------------------------
# Build inference dataset (next 24 hours)
# ---------------------------------------------------------------
now = datetime.datetime.utcnow()
hours = [(now + datetime.timedelta(hours=i)) for i in range(24)]

df = spark.createDataFrame(
    [(h, h.hour) for h in hours],
    ["timestamp", "hour"]
)

assembler = VectorAssembler(
    inputCols=["hour"],
    outputCol="features"
)
df_feat = assembler.transform(df)

# ---------------------------------------------------------------
# Predict
# ---------------------------------------------------------------
pred = model.transform(df_feat).select(
    "timestamp",
    F.col("prediction").alias("predicted_temperature")
)

# ---------------------------------------------------------------
# Save predictions
# ---------------------------------------------------------------
output_path = f"s3://{output_bucket}/predictions/"
pred.write.mode("overwrite").parquet(output_path)

print("Inference completed:", output_path)
