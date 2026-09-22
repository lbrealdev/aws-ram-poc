output "resource_association_ids" {
  description = "IDs of the resource associations (resource ARN comma share ARN)."
  value       = [for a in aws_ram_resource_association.this : a.id]
}

output "principal_association_ids" {
  description = "IDs of the principal associations (share ARN comma principal)."
  value       = [for a in aws_ram_principal_association.this : a.id]
}
