# Part 1 — count
# Same settings, repeated N times. count.index is 0, 1, 2, ...
# The human name uses count.index + 1 so the files are web-1, web-2, web-3.

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
  ami           = "ami-example"
  instance_type = "t2.micro"
}

resource "local_file" "web" {
  count = 3

  filename = "${path.module}/out/web-${count.index + 1}.txt"
  content  = "name=web-${count.index + 1}\ncount_index=${count.index}\nami=${local.ami}\ninstance_type=${local.instance_type}\n"
}

output "filenames" {
  value = local_file.web[*].filename
}

output "first_instance_file" {
  value = local_file.web[0].filename
}
