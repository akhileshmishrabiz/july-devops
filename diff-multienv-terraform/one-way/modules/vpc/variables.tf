variable "name" {
  description = "Name prefix for the VPC and subnet"
  type        = string
}

variable "cidr_block" {
  description = "VPC CIDR"
  type        = string
}

variable "subnet_cidr" {
  description = "Subnet CIDR"
  type        = string
}

variable "availability_zone" {
  description = "Availability zone for the subnet"
  type        = string
}
