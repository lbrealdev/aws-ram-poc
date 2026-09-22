# aws-ram-poc — Agent Guide

## Project

PoC for AWS Resource Access Manager (AWS RAM) with the Terraform AWS provider.
Read `README.md` for RAM behavior. This file is how to work in the repo.

Keep changes small. Prefer the minimum that proves the share path.

## Do / don't

- Do work on a branch and open a PR. Never commit on `main`. Never force-push.
- Do not commit secrets, `*.tfvars`, or `*.tfstate`.
- Do not apply or destroy against accounts the user did not name.
- Do not invent Terraform modules or layout until a later PR asks for them.

## Tooling

Toolchain is `mise.toml` + `justfile`. Do not install tools ad hoc.

```bash
mise trust && mise install
just init
just fmt
just validate
just plan    # needs AWS creds; skip if unavailable
```

Without AWS credentials, only the offline loop: `just init`, `just fmt`, `just validate`.

## Versions

When Terraform lands: Terraform `>= 1.2`, AWS provider `>= 6.0`, pinned in `versions.tf`.

## Git

| Prefix | Branch | Commit |
|--------|--------|--------|
| `feat` | `feat/short-name` | `feat(ram): short description` |
| `fix` | `fix/short-name` | `fix: short description` |
| `docs` | `docs/short-name` | `docs: short description` |
| `chore` | — | `chore: short description` |

Use `git` for version control. Prefer Cursor cloud agent / PR for GitHub writes unless the user asks otherwise.
