# Part 2 — for_each on a set
# for_each accepts a map or a set of strings. A list has to be converted with toset().
# The extra "web-1" stays in the list and disappears from the set, so only three files are created.

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
  names = ["web-1", "web-2", "web-3", "web-1"]
}

resource "local_file" "web" {
  # for_each = local.names
  for_each = toset(local.names)

  filename = "${path.module}/out/${each.value}.txt"
  content  = "each.key=${each.key}\neach.value=${each.value}\n"
}

output "list_length" {
  value = length(local.names)
}

output "set_length" {
  value = length(toset(local.names))
}

output "filenames" {
  value = sort(values(local_file.web)[*].filename)
}
