resource "aws_s3_bucket" "raw" {
  bucket = "raw-weather-${var.project_id}"
}

resource "aws_s3_bucket_public_access_block" "raw_block" {
  bucket                  = aws_s3_bucket.raw.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "processed" {
  bucket = "processed-weather-${var.project_id}"
}

resource "aws_s3_bucket_public_access_block" "processed_block" {
  bucket                  = aws_s3_bucket.processed.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "ml_output" {
  bucket = "ml-output-weather-${var.project_id}"
}

resource "aws_s3_bucket_public_access_block" "ml_output_block" {
  bucket                  = aws_s3_bucket.ml_output.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}