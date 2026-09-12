variable "environment" {
  description = "Environment"
  type = string
  default = "prod"
}

variable "prefix" {
  description = "Prefix"
  type = string
  default = "tf2t"
}


variable "rds_instance_class" {
  description = "RDS instance class"
  type = string
}

variable "container_name" {
  description = "Container name"
  type = string
  default = "2tier-app"
}

variable "app_image" {
  description = "App image"
  type = string
  default = "879381241087.dkr.ecr.ap-south-1.amazonaws.com/dev-tf2t:latest"
}

variable "port" {
  description = "Port"
  type = number
  default = 8000
}

variable "cpu" {
  description = "CPU"
  type = number
  default = 512  
}

variable "memory" {
  description = "Memory"
  type = number
  default = 1024
}

variable "ecs_task_def" {
  description = "ECS task definition"
  type = string
  default = "2tier-appjuly"
}

variable "aws_region" {
  description = "AWS region"
  type = string
  default = "ap-south-1"
}

variable "domain_name" {
  default = "mansipandey.in"
}

variable "subdomain_name" {
  default = "tf2t"
}

# tf2t.mansipandey.in