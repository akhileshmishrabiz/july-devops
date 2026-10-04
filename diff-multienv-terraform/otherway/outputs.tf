output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "rds_endpoint" {
  value = aws_db_instance.this.endpoint
}
