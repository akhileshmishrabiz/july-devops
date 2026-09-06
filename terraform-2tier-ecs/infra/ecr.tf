# ecr repository

resource "aws_ecr_repository" "ecr_repo" {
  name = "${var.environment}-${var.prefix}-app"
}


