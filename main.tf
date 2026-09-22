module "ram_share" {
  source = "./modules/ram_share"

  name                      = var.share_name
  allow_external_principals = var.allow_external_principals
  permission_arns           = var.permission_arns
  tags                      = var.tags
}
