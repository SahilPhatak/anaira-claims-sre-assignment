# Simulate "Production Account"
provider "aws" {
  alias      = "prod"
  region     = "ap-south-1"
  access_key = "test"
  secret_key = "test"

  skip_credentials_validation = true
  skip_metadata_api_check = true
  skip_requesting_account_id = true
  s3_use_path_style = true

  endpoints {
    s3  = "http://localhost:4566"
    sqs = "http://localhost:4566"
    iam = "http://localhost:4566"
  }
}

# S3 Bucket for Claims Archive (PII data)
resource "aws_s3_bucket" "claims_archive" {
  provider = aws.prod
  bucket   = "anaira-claims-archive-prod"
}

# S3 Public Access Block (security best practice)
resource "aws_s3_bucket_public_access_block" "claims_block" {
  provider = aws.prod
  bucket   = aws_s3_bucket.claims_archive.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
# Enable versioning (compliance requirement)
resource "aws_s3_bucket_versioning" "claims_versioning" {
  provider = aws.prod
  bucket   = aws_s3_bucket.claims_archive.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption (DPDP Act requirement)
resource "aws_s3_bucket_server_side_encryption_configuration" "claims_encryption" {
  provider = aws.prod
  bucket   = aws_s3_bucket.claims_archive.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lifecycle policy (archive to Glacier after 90 days)
resource "aws_s3_bucket_lifecycle_configuration" "claims_lifecycle" {
  provider = aws.prod
  bucket   = aws_s3_bucket.claims_archive.id

  rule {
    id     = "archive-old-claims"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}

# SQS Queue for High-Priority Claims
resource "aws_sqs_queue" "priority_claims" {
  provider = aws.prod
  name     = "priority-claims-queue"

  # Encryption at rest
  sqs_managed_sse_enabled = true

  # Dead-letter queue after 3 retries
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue" "dlq" {
  provider = aws.prod
  name     = "priority-claims-dlq"
#   Encryption at rest
  sqs_managed_sse_enabled = true
}

# IAM Policy (enforce encryption)
resource "aws_iam_policy" "claims_policy" {
  provider = aws.prod
  name     = "ClaimsProcessorPolicy"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "${aws_s3_bucket.claims_archive.arn}/*"

        Condition = {
          StringEquals = {
            "s3:x-amz-server-side-encryption" = "AES256"
          }
        }
      }
    ]
  })
}

# Output endpoints for K8s ConfigMap
output "s3_endpoint" {
  value = "http://localhost:4566"
}

output "sqs_queue_url" {
  value = aws_sqs_queue.priority_claims.url
}