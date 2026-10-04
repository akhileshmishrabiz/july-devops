# Part 7 — dynamic blocks
# A dynamic block repeats a nested block. Add an object to ingress_rules and another
# ingress block appears. The iterator name below is `rule`, so the values are rule.value.*.
# Inside a dynamic block the default iterator name is the block type (here, `ingress`).
# An explicit iterator keeps that name from clashing with each.key / each.value
# when the resource itself also uses for_each.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

variable "vpc_id" {
  type        = string
  description = "Existing VPC for plan and apply. terraform validate does not need a value."
}

variable "ingress_rules" {
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr        = string
  }))
  description = "Ingress rules. One dynamic block entry is created per object."
  default = [
    {
      description = "http"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr        = "0.0.0.0/0"
    },
    {
      description = "https"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr        = "0.0.0.0/0"
    },
  ]
}

resource "aws_security_group" "app" {
  name        = "lab-app"
  description = "App security group built from ingress_rules"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    iterator = rule

    content {
      description = rule.value.description
      from_port   = rule.value.from_port
      to_port     = rule.value.to_port
      protocol    = rule.value.protocol
      cidr_blocks = [rule.value.cidr]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
