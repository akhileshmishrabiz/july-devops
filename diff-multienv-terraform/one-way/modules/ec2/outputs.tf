output "instance_id" {
  description = "Instance id"
  value       = aws_instance.this.id
}

output "private_ip" {
  description = "Instance private IP"
  value       = aws_instance.this.private_ip
}
