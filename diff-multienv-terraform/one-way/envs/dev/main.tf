data "aws_caller_identity" "current" {}

locals {
  name = "${var.environment}-${var.prefix}"
}

module "vpc" {
  source = "../../modules/vpc"

  name              = local.name
  cidr_block        = var.vpc_cidr
  subnet_cidr       = var.subnet_cidr
  availability_zone = var.availability_zone
}

module "sg" {
  source = "../../modules/sg"

  name     = local.name
  vpc_id   = module.vpc.vpc_id
  vpc_cidr = var.vpc_cidr
}

module "s3" {
  source = "../../modules/s3"

  bucket_name = "${local.name}-${data.aws_caller_identity.current.account_id}"
}

module "ec2" {
  source = "../../modules/ec2"

  name              = local.name
  instance_type     = var.instance_type
  subnet_id         = module.vpc.subnet_id
  security_group_id = module.sg.security_group_id
}
