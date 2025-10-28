# AWS Secrets Manager secret for RDS password
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.project_name}/rds/password"
  recovery_window_in_days = 7

  tags = {
    Name = "${var.project_name}-rds-password"
  }

  lifecycle {
    ignore_changes = [tags_all]
  }
}

# Store the RDS password in Secrets Manager
resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
  })
}

# IAM policy to allow ECS tasks to read secrets
resource "aws_iam_role_policy" "ecs_task_secrets" {
  name = "${var.project_name}-ecs-task-secrets"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.db_password.arn
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = "*"
      }
    ]
  })
}
