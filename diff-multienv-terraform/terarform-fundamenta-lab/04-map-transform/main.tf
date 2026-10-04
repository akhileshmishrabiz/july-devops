# Part 4 — build the map from a list
# Callers edit a list. The for expression turns that list into the map for_each needs.
# Left of => becomes the key. Right of => becomes the value.

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
  instance_list = [
    {
      name          = "web-1"
      ami           = "ami-amazon-linux"
      instance_type = "t2.micro"
    },
    {
      name          = "web-2"
      ami           = "ami-ubuntu"
      instance_type = "t3.medium"
    },
    {
      name          = "web-3"
      ami           = "ami-debian"
      instance_type = "t3.large"
    },
  ]

  instance_map = {
    for instance in local.instance_list : instance.name => instance
  }
}

resource "local_file" "web" {
  for_each = local.instance_map

  filename = "${path.module}/out/${each.key}.txt"
  content  = "name=${each.key}\nami=${each.value.ami}\ninstance_type=${each.value.instance_type}\n"
}

output "instance_map" {
  value = local.instance_map
}

output "first_list_item_name" {
  value = local.instance_list[0].name
}

output "second_list_item_name" {
  value = local.instance_list[1].name
}
