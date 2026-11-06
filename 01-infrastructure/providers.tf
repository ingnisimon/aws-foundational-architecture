terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # We will add the S3/DynamoDB remote backend block here during Phase 3
}

provider "aws" {
  region = "us-east-1" # Change this if you prefer a different AWS region
}
