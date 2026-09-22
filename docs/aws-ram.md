# AWS Resource Access Manager

Reference for how AWS RAM sharing works in this PoC. Terraform details live in [terraform.md](./terraform.md).

Architecture diagrams for this PoC (Account A / Account B, same Org X): [architectures.md](./architectures.md).

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

## Constraints that bite

- **Region.** The share, the resource association, and the consumer lookup must target the Region where the resource exists. A subnet shared from `us-east-1` is not visible from `eu-west-1`.
- **Organization-only resources.** Some types (notably EC2 subnets) can be shared only from an account that is a member of an organization with RAM sharing enabled. `allow_external_principals` must stay off for those types.
- **One permission per resource type per share.** A second permission ARN for the same type is rejected.
- **Invitations are not instantaneous.** The accepter depends on the principal association. If the association is still propagating, the first apply of the accepter can fail; re-apply, or depend on the association explicitly (as in the example).
- **Management account only** for `aws_ram_sharing_with_organization`. Member accounts cannot enable it.
- **Exclusive vs. granular.** Pick one association style per share.
- **Deleted shares linger.** After you delete a resource share, it stays visible with status `DELETED` for about two hours, then disappears. The shared AWS resource itself is not deleted. See [Deleting a resource share](https://docs.aws.amazon.com/ram/latest/userguide/working-with-sharing-delete.html).
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
- [Deleting a resource share in AWS RAM](https://docs.aws.amazon.com/ram/latest/userguide/working-with-sharing-delete.html)
