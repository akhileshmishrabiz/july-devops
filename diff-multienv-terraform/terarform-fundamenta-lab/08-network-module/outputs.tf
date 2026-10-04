output "vpc_id" {
  description = "VPC id returned by the module."
  value       = module.network.vpc_id
}

output "vpc_name" {
  description = "VPC name returned by the module."
  value       = module.network.vpc_name
}

output "public_subnet_ids" {
  description = "Public subnet ids, keyed by the name in public_subnet_data."
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet ids, keyed by the name in private_subnet_data."
  value       = module.network.private_subnet_ids
}

output "nat_gateway_count" {
  description = "How many NAT gateways the module decided to create."
  value       = module.network.nat_gateway_count
}

output "first_public_cidr" {
  description = "List index 0. The first object in public_subnet_data."
  value       = var.public_subnet_data[0].cidr
}

output "second_public_cidr" {
  description = "List index 1. The second object in public_subnet_data."
  value       = var.public_subnet_data[1].cidr
}
