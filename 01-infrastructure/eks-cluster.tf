resource "aws_eks_cluster" "main" {
  name     = "foundational-architecture-cluster"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.30"

  vpc_config {
    subnet_ids              = aws_subnet.private[*].id
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  tags = {
    Environment = "dev"
    Name        = "foundational-architecture-eks-cluster"
  }
}
