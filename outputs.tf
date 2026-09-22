output "ram_share_arn" {
  description = "ARN of the AWS RAM resource share."
  value       = module.ram_share.arn
}

output "ram_share_id" {
  description = "ID of the AWS RAM resource share."
  value       = module.ram_share.id
}
