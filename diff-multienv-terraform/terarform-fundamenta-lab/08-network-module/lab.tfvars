aws_region  = "ap-south-1"
app_name    = "devops"
environment = "lab"
vpc_cidr    = "10.20.0.0/16"

enable_dns_hostnames    = true
need_nat_gateway        = false
need_single_nat_gateway = true

public_subnet_data = [
  {
    name              = "a"
    cidr              = "10.20.1.0/24"
    availability_zone = "ap-south-1a"
    prefix            = "public"
  },
  {
    name              = "b"
    cidr              = "10.20.2.0/24"
    availability_zone = "ap-south-1b"
    prefix            = "public"
  },
]

private_subnet_data = [
  {
    name              = "a"
    cidr              = "10.20.11.0/24"
    availability_zone = "ap-south-1a"
    prefix            = "app"
  },
  {
    name              = "b"
    cidr              = "10.20.12.0/24"
    availability_zone = "ap-south-1b"
    prefix            = "app"
  },
]
