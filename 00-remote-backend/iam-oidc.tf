# 1. GitHub OIDC Provider
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [
    "1b511abead59c6ce207077c0bf0e0043b1382612", # Current primary
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"  # Backup
  ]
}

# 2. IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name = "github-actions-deploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          # Hardcoded to the existing provider you imported
          Federated = "arn:aws:iam::384518871764:oidc-provider/token.actions.githubusercontent.com"
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # Matches your exact repository
            "token.actions.githubusercontent.com:sub" = "repo:ingnisimon/aws-foundational-architecture:*"
          }
        }
      }
    ]
  })
}

# 3. Attach Administrator Permissions
resource "aws_iam_role_policy_attachment" "github_actions_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
