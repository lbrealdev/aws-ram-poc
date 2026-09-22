# AWS RAM PoC

Proof of concept for sharing AWS resources with [AWS Resource Access Manager (AWS RAM)](https://docs.aws.amazon.com/ram/latest/userguide/what-is.html) and the [Terraform AWS provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs).

This repository documents the sharing model and the Terraform resources that implement it. It does not apply infrastructure.

## What AWS RAM does

AWS RAM lets the account that owns a resource share it with other AWS accounts, with an organization or organizational unit (OU) in AWS Organizations, and — for some resource types — with IAM roles, IAM users, and service principals.

You create the resource once in the owner account. Consumers use that same resource instead of a copy. There is no extra charge for AWS RAM itself or for creating a resource share. Usage charges stay with the resource type and are billed to the owner or the consumer according to that service's pricing.

Compared with attaching a resource-based policy by hand, RAM adds:

- Sharing with an organization or OU without listing every account ID.
- Shared resources appearing in the consumer's service console and API as if they lived in that account (for example, a shared VPC subnet shows up in the Amazon VPC console of the consumer).
- One managed permission per resource type on the share, instead of a separate policy per account.
- Visibility through CloudTrail and CloudWatch.

Ownership does not move. Sharing does not change the permissions or quotas that apply to the resource in the owner account. The owner can stop sharing at any time; consumers then lose access.

## How a share works

A **resource share** is the container. It has three parts:

1. One or more resources you own (by ARN).
2. One or more principals who may use those resources.
3. A managed permission for each resource type on the share. If you omit one, RAM attaches the default version of the AWS managed permission for that type. You can associate only one permission with each resource type on a given share.

**Principals** can be:

| Principal | Identifier |
| --- | --- |
| AWS account | 12-digit account ID |
| Organization | Organization ARN |
| Organizational unit | OU ARN |
| IAM role or user | Role or user ARN (supported resource types only) |
| Service principal | `service-id.amazonaws.com` (supported resource types only) |

AWS RAM is a Regional service. Consumers must access each shared resource from the same Region where it was created. Some resources are global; those follow the global endpoint rules of their service. Not every resource type can be shared, and some can be shared only inside an organization. The authoritative list is [Shareable AWS resources](https://docs.aws.amazon.com/ram/latest/userguide/shareable.html).

### Invitations vs. organization sharing

Two paths decide whether the consumer must accept an invitation.

**Outside an organization, or with sharing-with-Organizations disabled.** Associating an account sends an invitation. The consumer must accept it before the resources become available. Organization and OU principals cannot be used.

**Inside an organization, with sharing enabled.** Accounts, the organization, and OUs in the same organization get access automatically. No invitation is sent. Accounts outside the organization still receive an invitation, and only if the share allows external principals.

Enabling sharing with Organizations must be done from the organization's management account, and the organization must have all features enabled. Use the RAM API (`ram:EnableSharingWithAwsOrganization`), not only `organizations:EnableAWSServiceAccess`. The RAM path creates the service-linked role `AWSServiceRoleForResourceAccessManager`. Enabling trusted access from the Organizations console alone does not create that role, and intra-organization shares then fail.

By default, a consumer that leaves the organization loses access to shares it received as an organization member. For account-to-account shares created with `RetainSharingOnAccountLeaveOrganization` (which requires `allowExternalPrincipals`), RAM sends an invitation and the consumer keeps access after leaving. That setting applies only to new shares, only to individual accounts (not to an OU or the whole organization), and cannot be used with resource types that can be shared only inside an organization.

### Managed permissions

Every resource type on a share has exactly one managed permission:

- **AWS managed permissions** are maintained by AWS. RAM attaches the default version when you do not specify one.
- **Customer managed permissions** are JSON policy templates (`Effect`, `Action`, and optional `Condition`) that you author for least privilege. Not every resource type supports them.

Customer managed permissions are versioned. Associating a permission ARN pins the share to that permission; changing the default version does not automatically move existing shares.

## Terraform AWS provider

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

## Constraints that bite

- **Region.** The share, the resource association, and the consumer lookup must target the Region where the resource exists. A subnet shared from `us-east-1` is not visible from `eu-west-1`.
- **Organization-only resources.** Some types (notably EC2 subnets) can be shared only from an account that is a member of an organization with RAM sharing enabled. `allow_external_principals` must stay off for those types.
- **One permission per resource type per share.** A second permission ARN for the same type is rejected.
- **Invitations are not instantaneous.** The accepter depends on the principal association. If the association is still propagating, the first apply of the accepter can fail; re-apply, or depend on the association explicitly (as in the example).
- **Management account only** for `aws_ram_sharing_with_organization`. Member accounts cannot enable it.
- **Exclusive vs. granular.** Pick one association style per share.
- **Leaving the organization** drops access unless the share was created with `retain_sharing_on_account_leave_organization` and the consumer accepted the invitation.

## IAM

Typical owner-account actions: `ram:CreateResourceShare`, `ram:AssociateResourceShare`, `ram:AssociateResourceSharePermission`, `ram:DisassociateResourceShare`, `ram:DeleteResourceShare`, `ram:GetResourceShares`, `ram:EnableSharingWithAwsOrganization` (management account), plus `iam:CreateServiceLinkedRole` the first time sharing with Organizations is enabled.

Typical consumer-account actions: `ram:AcceptResourceShareInvitation`, `ram:RejectResourceShareInvitation`, `ram:GetResourceShareInvitations`.

The action list changes. Check [Actions, resources, and condition keys for AWS Resource Access Manager](https://docs.aws.amazon.com/service-authorization/latest/reference/list_ram.html) rather than copying a stale policy.

## References

- [What is AWS Resource Access Manager?](https://docs.aws.amazon.com/ram/latest/userguide/what-is.html)
- [Sharing your AWS resources](https://docs.aws.amazon.com/ram/latest/userguide/getting-started-sharing.html)
- [Shareable AWS resources](https://docs.aws.amazon.com/ram/latest/userguide/shareable.html)
- [Managing permissions in AWS RAM](https://docs.aws.amazon.com/ram/latest/userguide/security-ram-permissions.html)
- [Terraform AWS provider — RAM resources](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
