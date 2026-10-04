variable "name" {
  description = "Name prefix for the instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "subnet_id" {
  description = "Subnet id"
  type        = string
}

variable "security_group_id" {
  description = "Security group id"
  type        = string
}
