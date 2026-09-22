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
 │  (identity policy SSM)   │            │         │                    │
 │                          │            │         ▼                    │
 │  No RAM invitation when  │            │  AWS RAM resource share      │
 │  A and B are in Org X    │            │    ├─ resource: param ARN  │
 │  with org sharing on     │            │    └─ principal: Acct A ID │
 └──────────▲───────────────┘            │  allow_external_principals │
            │                            │  (false is enough in-org)  │
            │      share association     │                            │
            └────────────────────────────┤                            │
                                         └──────────────────────────────┘
```

### Steps

1. Account B creates the Advanced-tier parameter.
2. Account B creates the RAM resource share.
3. Account B associates the parameter ARN with the share.
4. Account B associates Account A's 12-digit account ID as principal.
5. Skip invitation when both accounts are in Org X with RAM sharing with Organizations enabled.
6. Account A's EC2 role needs `ssm:GetParameter` (and related) on the shared parameter ARN.

The IAM role is authorization **inside** Account A after the share grants the account. For Parameter Store, the RAM principal is typically the consumer **account**, not the role ARN.

## Deleted shares

Deleting a resource share does not delete the underlying AWS resource (the parameter stays). The share moves to status `DELETED` and remains visible in the console/API for about **two hours**, then disappears. There is no purge action.

Official docs: [Deleting a resource share in AWS RAM](https://docs.aws.amazon.com/ram/latest/userguide/working-with-sharing-delete.html).
