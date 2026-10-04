environment = "prod"
prefix      = "dummy"
vpc_cidr    = "10.20.0.0/16"

public_subnet_data = [
  {
    cidr              = "10.20.1.0/24"
    availability_zone = "ap-south-1a"
    prefix            = "public"
  },
  {
    cidr              = "10.20.2.0/24"
    availability_zone = "ap-south-1b"
    prefix            = "public"
  }
]

private_subnet_data = [
  {
    cidr              = "10.20.3.0/24"
    availability_zone = "ap-south-1a"
    prefix            = "private"
  },
  {
    cidr              = "10.20.4.0/24"
    availability_zone = "ap-south-1b"
    prefix            = "private"
  }
]
