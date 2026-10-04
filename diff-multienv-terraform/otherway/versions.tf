terraform {
  required_version = "1.16.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # Backend values live in vars/*.tfbackend so the same code
  # maps to a different state file per environment:
  #   terraform init -backend-config=vars/dev.tfbackend
  #   terraform init -backend-config=vars/prod.tfbackend -reconfigure
  backend "s3" {}
}
