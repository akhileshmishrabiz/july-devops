terraform {
  required_version = "1.16.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
      # ~> vs >= is used to specify the range of versions
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}


terraform {
  backend "s3" {
    bucket = "state-bucket-879381241087"
    key = "dev/july-devops/terraform-2tier-ecs/terraform.tfstate"
    region = "ap-south-1"
    use_lockfile = true
    encrypt = true
    kms_key_id = "arn:aws:kms:ap-south-1:879381241087:key/6f28b59d-9308-4068-a56f-f06563062199"
  }
}