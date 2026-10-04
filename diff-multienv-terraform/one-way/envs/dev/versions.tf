terraform {
  required_version = "1.16.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}



terraform {
  backend "s3" {
    bucket = "terraform-state-bucket"
    key = "diff-multienv-terraform/dev/terraform.tfstate"
    region = "ap-south-1"
  }
}