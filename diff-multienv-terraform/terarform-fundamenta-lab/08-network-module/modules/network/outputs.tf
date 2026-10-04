output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "vpc_name" {
  description = "Name tag of the VPC."
  value       = aws_vpc.main.tags["Name"]
}

output "public_subnet_ids" {
  description = "Map of public subnet name to subnet id."
  value       = { for name, subnet in aws_subnet.public : name => subnet.id }
}

output "private_subnet_ids" {
  description = "Map of private subnet name to subnet id."
  value       = { for name, subnet in aws_subnet.private : name => subnet.id }
}

output "nat_gateway_count" {
  description = "Number of NAT gateways created from need_nat_gateway and need_single_nat_gateway."
  value       = local.nat_count
}
