# Terraform AWS provider (RAM)

Terraform resources and examples for this PoC. RAM behavior and constraints: [aws-ram.md](./aws-ram.md).

Provider: [`hashicorp/aws`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs), RAM (Resource Access Manager) resources. Examples below match the provider docs as of v6.66.0. Confirm argument names against the registry before applying; the provider adds a top-level `region` argument on these resources that overrides the provider-level Region.

RAM resources are split on purpose. The share, the principals, and the resources are separate Terraform resources so each can be added or removed without recreating the share.

| Resource | Role |
| --- | --- |
| [`aws_ram_resource_share`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_resource_share) | Creates the share. |
| [`aws_ram_principal_association`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_principal_association) | Associates one principal. |
| [`aws_ram_resource_association`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_resource_association) | Associates one resource ARN. |
| [`aws_ram_resource_share_accepter`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_resource_share_accepter) | Accepts an invitation in the consumer account. |
| [`aws_ram_sharing_with_organization`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_sharing_with_organization) | Enables sharing with Organizations (management account only). |
| [`aws_ram_permission`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_permission) | Creates a customer managed permission. |
| [`aws_ram_resource_share_associations_exclusive`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ram_resource_share_associations_exclusive) | Owns the full set of principals and resources on one share. |

Data source: [`aws_ram_resource_share`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ram_resource_share) looks up a share by name, status, or tag. `resource_owner` is `SELF` or `OTHER-ACCOUNTS`.

### Resource share

```hcl
resource "aws_ram_resource_share" "example" {
  name                      = "example"
  allow_external_principals = true

  # Optional. One permission ARN per resource type on the share.
  # Omitted => RAM attaches the default AWS managed permission per type.
  # permission_arns = [aws_ram_permission.example.arn]

  # Optional. Keep account-to-account access after the consumer leaves the org.
  # Requires allow_external_principals = true. Set only at creation.
  # resource_share_configuration {
  #   retain_sharing_on_account_leave_organization = true
  # }

  tags = {
    Environment = "Production"
  }
}
```

`allow_external_principals` controls whether principals outside the organization can be associated. Leave it `false` when the share must stay inside the organization (required for some resource types, including subnets in many setups).

### Associate a principal and a resource

```hcl
resource "aws_ram_principal_association" "account" {
  principal          = "111111111111" # account ID, org ARN, or OU ARN
  resource_share_arn = aws_ram_resource_share.example.arn
}

resource "aws_ram_resource_association" "subnet" {
  resource_arn       = aws_subnet.example.arn
  resource_share_arn = aws_ram_resource_share.example.arn
}
```

Share an organization by passing the organization ARN instead of an account ID. This only works after `aws_ram_sharing_with_organization` has been applied from the management account.

```hcl
resource "aws_ram_principal_association" "org" {
  principal          = aws_organizations_organization.example.arn
  resource_share_arn = aws_ram_resource_share.example.arn
}
```

### Enable sharing with Organizations

```hcl
resource "aws_ram_sharing_with_organization" "example" {}
```

Apply this in the management account. Do not fake the same effect by adding `ram.amazonaws.com` to `aws_service_access_principals` on `aws_organizations_organization`; that path does not create the RAM service-linked role.

### Accept an invitation (external or cross-organization)

Skip the accepter when both accounts are in the same organization and sharing with Organizations is enabled. Otherwise the consumer account must accept.

```hcl
provider "aws" {
  profile = "consumer"
}

provider "aws" {
  alias   = "owner"
  profile = "owner"
}

resource "aws_ram_resource_share" "sender" {
  provider = aws.owner

  name                      = "tf-example-share"
  allow_external_principals = true
}

resource "aws_ram_principal_association" "invite" {
  provider = aws.owner

  principal          = data.aws_caller_identity.consumer.account_id
  resource_share_arn = aws_ram_resource_share.sender.arn
}

data "aws_caller_identity" "consumer" {}

resource "aws_ram_resource_share_accepter" "receiver" {
  share_arn = aws_ram_principal_association.invite.resource_share_arn
}
```

The accepter runs in the consumer provider (the default provider above). `share_arn` is the resource share ARN, not the invitation ARN. The resource exports `status` (`PENDING`, `ACTIVE`, `FAILED`, `DELETING`, `DELETED`), `invitation_arn`, `sender_account_id`, and `resources`.

### Customer managed permission

```hcl
resource "aws_ram_permission" "backup" {
  name          = "custom-backup"
  resource_type = "backup:BackupVault" # <service-code>:<resource-type>

  policy_template = jsonencode({
    Effect = "Allow"
    Action = [
      "backup:ListProtectedResourcesByBackupVault",
      "backup:ListRecoveryPointsByBackupVault",
      "backup:DescribeRecoveryPoint",
      "backup:DescribeBackupVault",
    ]
  })
}
```

Pass `aws_ram_permission.backup.arn` in `permission_arns` on the resource share. The name must be unique in the Region.

### Exclusive associations

`aws_ram_resource_share_associations_exclusive` is the alternative when Terraform should be the only writer of principals and resources on a share. Anything not listed is disassociated. Destroying it disassociates everything it manages.

Do not combine it with `aws_ram_principal_association` or `aws_ram_resource_association` on the same share. The two styles fight and the plan never settles. Service principals cannot be mixed with account, organization, OU, or IAM principals in the same exclusive resource. The optional `sources` argument is only valid when every principal is a service principal; it restricts which account IDs that service may access the shared resources from.

```hcl
resource "aws_ram_resource_share_associations_exclusive" "example" {
  resource_share_arn = aws_ram_resource_share.example.arn

  principals = [
    "111111111111",
    "222222222222",
  ]

  resource_arns = [
    aws_subnet.example.arn,
  ]
}
```

