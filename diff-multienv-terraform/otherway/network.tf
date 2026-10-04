module "network" {
  source = "github.com/akhileshmishrabiz/network-module"

  vpc_cidr             = var.vpc_cidr
  vpc_name             = local.name
  enable_dns_hostnames = true
  # NAT stays off. This flag makes the module attach every private subnet
  # to the single private route table, which RDS needs across two AZs.
  need_nat_gateway        = false
  need_single_nat_gateway = true

  public_subnet_data  = var.public_subnet_data
  private_subnet_data = var.private_subnet_data
}
