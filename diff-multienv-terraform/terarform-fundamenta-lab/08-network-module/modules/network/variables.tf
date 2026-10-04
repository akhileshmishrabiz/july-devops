variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC."
}

variable "vpc_name" {
  type        = string
  description = "Name tag for the VPC. The caller builds this. The module does not hardcode it."
}

variable "enable_dns_hostnames" {
  type        = bool
  description = "Enable DNS hostnames in the VPC. Off unless the caller opts in."
  default     = false
}

variable "enable_dns_support" {
  type        = bool
  description = "Enable DNS resolution in the VPC."
  default     = true
}

variable "public_subnet_data" {
  type = list(object({
    name              = string
    cidr              = string
    availability_zone = string
    prefix            = string
  }))
  description = "Public subnets to create. The length of this list is the number of public subnets."

  validation {
    condition     = length(var.public_subnet_data) == length(distinct([for subnet in var.public_subnet_data : subnet.name]))
    error_message = "public_subnet_data names must be unique. The name becomes the for_each key."
  }
}

variable "private_subnet_data" {
  type = list(object({
    name              = string
    cidr              = string
    availability_zone = string
    prefix            = string
  }))
  description = "Private subnets to create. The length of this list is the number of private subnets."

  validation {
    condition     = length(var.private_subnet_data) == length(distinct([for subnet in var.private_subnet_data : subnet.name]))
    error_message = "private_subnet_data names must be unique. The name becomes the for_each key."
  }
}

variable "need_nat_gateway" {
  type        = bool
  description = "Create NAT gateways when true. Creates none when false."
  default     = false
}

variable "need_single_nat_gateway" {
  type        = bool
  description = "One shared NAT in the first public subnet when true. One NAT per public subnet when false."
  default     = false
}
