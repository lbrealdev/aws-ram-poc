output "arn" {
  description = "ARN of the resource share."
  value       = aws_ram_resource_share.this.arn
}

output "id" {
  description = "ID of the resource share."
  value       = aws_ram_resource_share.this.id
}
