provider "aws" {
  region = "us-east-1"
}

# 1. S3 Bucket for State Storage
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "foundational-architecture-tf-state-ingnisimon-aws"
  force_destroy = true

  tags = {
    Name        = "Terraform State Storage"
    Environment = "dev"
  }
}

# 2. Enable S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 3. DynamoDB Table for State Locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "foundational-architecture-tf-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock Table"
    Environment = "dev"
  }
}
