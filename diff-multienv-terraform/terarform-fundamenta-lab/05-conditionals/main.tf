# Part 5 — conditionals with count
# condition ? value_when_true : value_when_false
# count = 1 creates the resource. count = 0 creates nothing.
# nat_count is the same decision the network module makes for NAT gateways.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

variable "want_instance" {
  type        = bool
  description = "Create the instance file when true."
  default     = true
}

variable "need_nat_gateway" {
  type        = bool
  description = "Whether any NAT gateway should exist."
  default     = true
}

variable "need_single_nat_gateway" {
  type        = bool
  description = "One shared NAT when true. One NAT per public subnet when false."
  default     = true
}

variable "public_subnet_count" {
  type        = number
  description = "How many public subnets the caller asked for."
  default     = 2
}

locals {
  nat_count = (
    var.need_nat_gateway
    ? (var.need_single_nat_gateway ? 1 : var.public_subnet_count)
    : 0
  )
}

resource "local_file" "web" {
  count = var.want_instance ? 1 : 0

  filename = "${path.module}/out/web.txt"
  content  = "created because want_instance is true\n"
}

output "nat_count" {
  value = local.nat_count
}

output "instance_file_count" {
  value = length(local_file.web)
}
