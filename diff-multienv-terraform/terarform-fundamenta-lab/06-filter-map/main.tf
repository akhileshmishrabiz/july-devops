# Part 6 — a second map for a subset
# Every service becomes a file. A load balancer file is created only where need_alb is true.
# The filter is a for expression with an if clause. Callers still edit one list.

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
  services = [
    {
      name     = "frontend"
      image    = "frontend:1.0"
      port     = 80
      need_alb = true
    },
    {
      name     = "backend"
      image    = "backend:1.0"
      port     = 8000
      need_alb = false
    },
  ]

  services_map = {
    for service in local.services : service.name => service
  }

  alb_services = {
    for name, service in local.services_map : name => service
    if service.need_alb
  }
}

resource "local_file" "service" {
  for_each = local.services_map

  filename = "${path.module}/out/${each.key}.txt"
  content  = "image=${each.value.image}\nport=${each.value.port}\nneed_alb=${each.value.need_alb}\n"
}

resource "local_file" "alb" {
  for_each = local.alb_services

  filename = "${path.module}/out/${each.key}-alb.txt"
  content  = "attach ${each.key} to the load balancer on port ${each.value.port}\n"
}

output "service_keys" {
  value = keys(local.services_map)
}

output "alb_keys" {
  value = keys(local.alb_services)
}
