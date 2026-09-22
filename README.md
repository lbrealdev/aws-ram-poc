# AWS RAM PoC

Proof of concept for sharing AWS resources with [AWS Resource Access Manager (AWS RAM)](https://docs.aws.amazon.com/ram/latest/userguide/what-is.html) and the [Terraform AWS provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs).

This repository documents the sharing model and will hold a small Terraform stack to exercise it. It does not apply infrastructure until you configure credentials and run plan/apply locally.

## Docs

| Doc | Contents |
| --- | --- |
| [docs/architectures.md](docs/architectures.md) | Org topology (Account A / B) and Parameter Store cross-account ASCII flows |
| [docs/aws-ram.md](docs/aws-ram.md) | What RAM does, share model, invitations vs Organizations, managed permissions, constraints, IAM, references |
| [docs/terraform.md](docs/terraform.md) | Provider resources, HCL examples (share, associations, accepter, permissions) |


## Architecture

Same AWS Organization (**Org X**): **Account A** consumes; **Account B** owns Parameter Store (Advanced) and the RAM share. Diagrams: [docs/architectures.md](docs/architectures.md).

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

**Status:** root stack + `modules/ram_share` (resource share only).

Associations, accepter, and Organizations sharing land in later PRs.

```bash
cp examples/default.tfvars.example terraform.tfvars
# edit terraform.tfvars
just init
just plan
```

| Path | Role |
| --- | --- |
| `modules/ram_share` | `aws_ram_resource_share` |
| `examples/default.tfvars.example` | Sample inputs (copy to local `terraform.tfvars`) |

Root variables: `aws_region`, `share_name`, `allow_external_principals`, `permission_arns`, `tags`.

Outputs: `ram_share_arn`, `ram_share_id`.
