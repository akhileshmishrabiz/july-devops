output "vpc_id" {
  value = module.vpc.vpc_id
}

output "subnet_id" {
  value = module.vpc.subnet_id
}

output "security_group_id" {
  value = module.sg.security_group_id
}

output "bucket_name" {
  value = module.s3.bucket_name
}

output "instance_id" {
  value = module.ec2.instance_id
}
