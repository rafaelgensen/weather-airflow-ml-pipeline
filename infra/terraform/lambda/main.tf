locals {
  raw_bucket = "raw-weather-${var.project_id}"
}

resource "aws_lambda_function" "ingest_api" {
  function_name = "ingest-weather-api"
  role          = var.lambda_role_arn
  handler       = "main.lambda_handler"
  runtime       = "python3.10"
  timeout       = 30

  filename         = "${path.module}/package.zip"
  source_code_hash = filebase64sha256("${path.module}/package.zip")

  environment {
    variables = {
      PROJECT_ID = var.project_id
    }
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/package.zip"
}