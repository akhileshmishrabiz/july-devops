locals {
  vpc_name = "${var.app_name}-${var.environment}-vpc"
}

module "network" {
  source = "./modules/network"

  vpc_cidr                = var.vpc_cidr
  vpc_name                = local.vpc_name
  enable_dns_hostnames    = var.enable_dns_hostnames
  need_nat_gateway        = var.need_nat_gateway
  need_single_nat_gateway = var.need_single_nat_gateway

  public_subnet_data  = var.public_subnet_data
  private_subnet_data = var.private_subnet_data
}
