terraform {
  backend "s3" {
    # Replace with your exact globally unique bucket name
    bucket = "foundational-architecture-tf-state-ingnisimon-aws"
    key    = "state/terraform.tfstate"
    region = "us-east-1"

    # Must match the DynamoDB table name exactly
    use_lockfile = true
    encrypt      = true
  }
}
