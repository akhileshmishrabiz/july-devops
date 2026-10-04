# Part 3 — for_each on a map
# count repeats one configuration. A map gives each instance its own ami and instance_type.
# each.key is the map key. each.value is the object stored under that key.
# toset() cannot do this job: it only builds a set of strings, and these values are objects.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

locals {
  instances = {
    web-1 = {
      ami           = "ami-amazon-linux"
      instance_type = "t2.micro"
    }
    web-2 = {
      ami           = "ami-ubuntu"
      instance_type = "t3.medium"
    }
    web-3 = {
      ami           = "ami-debian"
      instance_type = "t3.large"
    }
  }
}

resource "local_file" "web" {
  for_each = local.instances

  filename = "${path.module}/out/${each.key}.txt"
  content  = "name=${each.key}\nami=${each.value.ami}\ninstance_type=${each.value.instance_type}\n"
}

output "web_2_instance_type" {
  value = local_file.web["web-2"].content
}
