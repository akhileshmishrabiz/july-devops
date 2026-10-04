variable "aws_region" {
  type        = string
  description = "AWS region for the provider."
}

variable "app_name" {
  type        = string
  description = "Short application name used in the VPC name."
}

variable "environment" {
  type        = string
  description = "Environment label used in the VPC name."
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC."
}

variable "enable_dns_hostnames" {
  type        = bool
  description = "Passed through to the network module."
}

variable "need_nat_gateway" {
  type        = bool
  description = "Create NAT gateways when true."
}

variable "need_single_nat_gateway" {
  type        = bool
  description = "One shared NAT when true. One NAT per public subnet when false."
}

variable "public_subnet_data" {
  type = list(object({
    name              = string
    cidr              = string
    availability_zone = string
    prefix            = string
  }))
  description = "Public subnets. One object creates one subnet."
}

variable "private_subnet_data" {
  type = list(object({
    name              = string
    cidr              = string
    availability_zone = string
    prefix            = string
  }))
  description = "Private app subnets. One object creates one subnet."
}
