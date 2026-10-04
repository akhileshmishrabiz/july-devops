provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Terraform   = "true"
      Repo        = "july-devops/diff-multienv-terraform/one-way"
      Environment = var.environment
    }
  }
}
