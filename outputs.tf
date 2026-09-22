output "ram_share_arn" {
  description = "ARN of the AWS RAM resource share."
  value       = module.ram_share.arn
}

output "ram_share_id" {
  description = "ID of the AWS RAM resource share."
  value       = module.ram_share.id
}

output "resource_association_ids" {
  description = "IDs of resource associations created by ram_associations."
  value       = module.ram_associations.resource_association_ids
}

output "principal_association_ids" {
  description = "IDs of principal associations created by ram_associations."
  value       = module.ram_associations.principal_association_ids
}
