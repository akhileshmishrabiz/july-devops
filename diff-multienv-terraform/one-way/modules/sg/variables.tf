variable "name" {
  description = "Name prefix for the security group"
  type        = string
}

variable "vpc_id" {
  description = "VPC id"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR allowed to reach the instance"
  type        = string
}
