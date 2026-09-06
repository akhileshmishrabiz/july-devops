provider "aws" {
  region = "ap-south-1"
  default_tags {
    tags = {
      Terraform = "true"
      Repo = "july-devops/terraform-2tier-ecs"
      
    }
  }
}


# provider "aws" {
#   region = "ap-south-2"
#   alias = "other-one"
# }