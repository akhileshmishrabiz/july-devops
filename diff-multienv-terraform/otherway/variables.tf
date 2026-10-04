variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "The environment to deploy to"
  type        = string
}

variable "prefix" {
  description = "The prefix to use for the resources"
  type        = string
  default     = "terraform"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
}

variable "public_subnet_data" {
  description = "Public subnets passed to the network module"
  type = list(object({
    cidr              = string
    availability_zone = string
    prefix            = string
  }))
}

variable "private_subnet_data" {
  description = "Private subnets passed to the network module"
  type = list(object({
    cidr              = string
    availability_zone = string
    prefix            = string
  }))
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}
