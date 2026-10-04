output "vpc_id" {
  description = "VPC id"
  value       = aws_vpc.this.id
}

output "subnet_id" {
  description = "Subnet id"
  value       = aws_subnet.this.id
}
