# 1. EKS Pod Identity Agent Addon
resource "aws_eks_addon" "pod_identity" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "eks-pod-identity-agent"

  depends_on = [aws_eks_node_group.main]
}

# 2. IAM Role with Pod Identity Trust Policy
resource "aws_iam_role" "app_pod_identity" {
  name = "${var.project_name}-app-pod-identity-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-app-pod-identity-role"
    Environment = var.environment
  }
}

# 3. Application Permission Policy (ECR & S3 Access Example)
resource "aws_iam_policy" "app_permissions" {
  name        = "${var.project_name}-app-permissions-policy"
  description = "IAM permissions granted to Kubernetes pods via EKS Pod Identity"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "s3:ListAllMyBuckets"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "app_pod_identity_attach" {
  role       = aws_iam_role.app_pod_identity.name
  policy_arn = aws_iam_policy.app_permissions.arn
}

# 4. EKS Pod Identity Association
resource "aws_eks_pod_identity_association" "app" {
  cluster_name    = aws_eks_cluster.main.name
  namespace       = "default"
  service_account = "foundational-app-sa"
  role_arn        = aws_iam_role.app_pod_identity.arn

  depends_on = [aws_eks_addon.pod_identity]
}
