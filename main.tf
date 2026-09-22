module "ram_share" {
  source = "./modules/ram_share"

  name                      = var.share_name
  allow_external_principals = var.allow_external_principals
  permission_arns           = var.permission_arns
  tags                      = var.tags
}

module "ram_associations" {
  source = "./modules/ram_associations"

  resource_share_arn = module.ram_share.arn
  resource_arns      = var.resource_arns
  principals         = var.principals
}
