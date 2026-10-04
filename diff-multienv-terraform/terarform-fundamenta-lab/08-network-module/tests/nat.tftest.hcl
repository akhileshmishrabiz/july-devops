# Plans the network module without calling AWS.
# Run from 08-network-module: terraform test

mock_provider "aws" {}

variables {
  aws_region              = "ap-south-1"
  app_name                = "devops"
  environment             = "lab"
  vpc_cidr                = "10.20.0.0/16"
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
}

run "nat_off" {
  command = plan

  assert {
    condition     = output.nat_gateway_count == 0
    error_message = "NAT should stay off when need_nat_gateway is false."
  }

  assert {
    condition     = output.vpc_name == "devops-lab-vpc"
    error_message = "VPC name should be app-environment-vpc."
  }

  assert {
    condition     = length(output.public_subnet_ids) == 2
    error_message = "Two public subnet objects should create two public subnets."
  }
}

run "single_nat" {
  command = plan

  variables {
    need_nat_gateway        = true
    need_single_nat_gateway = true
  }

  assert {
    condition     = output.nat_gateway_count == 1
    error_message = "A single NAT should produce a count of 1."
  }
}

run "nat_per_subnet" {
  command = plan

  variables {
    need_nat_gateway        = true
    need_single_nat_gateway = false
  }

  assert {
    condition     = output.nat_gateway_count == 2
    error_message = "One NAT per public subnet should produce a count of 2."
  }
}

run "three_subnets" {
  command = plan

  variables {
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
      {
        name              = "c"
        cidr              = "10.20.3.0/24"
        availability_zone = "ap-south-1c"
        prefix            = "public"
      },
    ]
  }

  assert {
    condition     = length(output.public_subnet_ids) == 3
    error_message = "Adding a third object should create a third public subnet."
  }
}
