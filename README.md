# AWS RAM PoC

Proof of concept for sharing AWS resources with [AWS Resource Access Manager (AWS RAM)](https://docs.aws.amazon.com/ram/latest/userguide/what-is.html) and the [Terraform AWS provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs).

This repository documents the sharing model and will hold a small Terraform stack to exercise it. It does not apply infrastructure until you configure credentials and run plan/apply locally.

## Docs

| Doc | Contents |
| --- | --- |
| [docs/aws-ram.md](docs/aws-ram.md) | What RAM does, share model, invitations vs Organizations, managed permissions, constraints, IAM, references |
| [docs/terraform.md](docs/terraform.md) | Provider resources, HCL examples (share, associations, accepter, permissions) |

Agent workflow: [AGENTS.md](AGENTS.md).

## Tooling

```bash
mise trust && mise install
just init
just fmt
just validate
just plan    # needs AWS credentials
```

Common aliases: `just sts` (caller identity), `just cleanup` (local Terraform artifacts only).

## Terraform stack

**Status:** not in the repo yet. The next PR adds the root stack and modules.

Planned shape (subject to that PR):

- Root wiring + `versions.tf` (Terraform `>= 1.2`, AWS provider `>= 6.0`)
- Modules for the share path (owner share / associations; consumer accepter when needed)
- `examples/*.tfvars.example` for local `terraform.tfvars` (never committed)

Until then, use [docs/terraform.md](docs/terraform.md) as the HCL reference and [docs/aws-ram.md](docs/aws-ram.md) for behavior and pitfalls (especially Organizations trusted access and Region constraints).
