resource "aws_ram_resource_share" "this" {
  name                      = var.name
  allow_external_principals = var.allow_external_principals
  permission_arns           = length(var.permission_arns) > 0 ? var.permission_arns : null
  tags                      = var.tags
}
