data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/package.zip"
}

resource "aws_lambda_function" "ingest_api" {
  function_name = "ingest-weather-api"
  role          = var.lambda_role_arn
  handler       = "main.lambda_handler"
  runtime       = "python3.10"
  timeout       = 30

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      PROJECT_ID = var.project_id
    }
  }

  depends_on = [data.archive_file.lambda_zip]
}
