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

# ECR Repository for Phase 5 application container images
resource "aws_ecr_repository" "app" {
  name                 = "foundational-architecture-app-repo"
  image_tag_mutability = "MUTABLE"
  force_delete         = true   # Automatically purges all pushed images during terraform destroy

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = "dev"
    Name        = "foundational-architecture-ecr"
  }
}
