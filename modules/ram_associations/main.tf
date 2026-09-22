resource "aws_ram_resource_association" "this" {
  for_each = toset(var.resource_arns)

  resource_arn       = each.value
  resource_share_arn = var.resource_share_arn
}

resource "aws_ram_principal_association" "this" {
  for_each = toset(var.principals)

  principal          = each.value
  resource_share_arn = var.resource_share_arn
}
