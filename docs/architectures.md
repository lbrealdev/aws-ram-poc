# Architectures

ASCII views of this PoC. Labels are generic: **Account A** (consumer), **Account B** (owner), **Org X** (same AWS Organization). No real account or OU names.

Both accounts are members of the same organization. Intra-organization shares with Organizations sharing enabled do **not** send a RAM invitation.

## Org topology

```
Org X
│
├── Account A — consumer
│     EC2 instance + IAM role (calls SSM APIs)
│
└── Account B — owner
      SSM Parameter Store (Advanced)
      AWS RAM resource share
```

Account A needs to reach a parameter that lives in Account B. Account B owns the parameter and the RAM share.

## Parameter Store cross-account flow

```
 Account A (consumer)                      Account B (owner)
 ┌──────────────────────────┐            ┌──────────────────────────────┐
 │  EC2                     │            │  SSM Parameter Store         │
 │    │                     │            │  (Advanced)                  │
 │    ▼                     │            │         │                    │
 │  IAM role ───────────────┼─GetParameter─────────┘                    │
 │  (may also need identity │            │         │                    │
 │   policy SSM on the ARN) │            │         ▼                    │
 │                          │            │  AWS RAM resource share      │
 │  No RAM invitation when  │            │    ├─ resource: param ARN  │
 │  A and B are in Org X    │            │    └─ principal: role ARN  │
 │  with org sharing on     │            │       (Account A IAM role) │
 └──────────▲───────────────┘            │  allow_external_principals │
            │                            │  (false is enough in-org)  │
            │      share association     │                            │
            └────────────────────────────┤                            │
                                         └──────────────────────────────┘
```

`ssm:Parameter` supports sharing with IAM roles and users (see [Shareable AWS resources](https://docs.aws.amazon.com/ram/latest/userguide/shareable.html)). This PoC associates the Account A role ARN as the RAM principal. You can instead use Account A's 12-digit account ID, an OU ARN, or the organization ARN.

### Steps

1. Account B creates the Advanced-tier parameter.
2. Account B creates the RAM resource share (and optional `permission_arns`).
3. Account B associates the parameter ARN with the share (`aws_ram_resource_association`).
4. Account B associates the principal — typically Account A's IAM role ARN (`aws_ram_principal_association`).
5. Skip invitation when both accounts are in Org X with RAM sharing with Organizations enabled.
6. Ensure the Account A role can call `ssm:GetParameter` (and related) on the shared parameter ARN when required by your identity policies.

## Deleted shares

Deleting a resource share does not delete the underlying AWS resource (the parameter stays). The share moves to status `DELETED` and remains visible in the console/API for about **two hours**, then disappears. There is no purge action.

Official docs: [Deleting a resource share in AWS RAM](https://docs.aws.amazon.com/ram/latest/userguide/working-with-sharing-delete.html).
