# Contributing

Thanks for helping improve this project. Issues and pull requests are welcome.

## Ground rules

- **Never put real environment values in committed files.** Use a `REPLACE_ME_<NAME>` placeholder
  in the committed file, your value in the gitignored `*.local` override, add the placeholder's
  description to `scripts/placeholders.py`, and run `scripts/placeholders.py docs`.

- **Never commit secrets.** No NetBird PATs, setup keys, Terraform state, private keys,
  certificates, or real AWS account IDs / domains. `gitleaks` runs in pre-commit and CI.
- Keep changes focused: one module or concern per pull request.
- Discuss large changes (new modules, breaking input changes) in an issue first.

## Toolchain

| Tool | Version |
|---|---|
| Terraform | 1.16.5 |
| Terragrunt | 1.1.6 |
| NetBird provider | `~> 0.0.11` |
| Helm | 3.x |

Versions are pinned in `config/versions.yaml`, `terragrunt/netbird-live/.terraform-version`
and `.terragrunt-version` (honoured by `tfenv` / `tgenv`).

```sh
pip install pre-commit && pre-commit install
```

## Repository layout

| Path | What it is |
|---|---|
| `netbird-terraform/modules/` | Reusable Terraform modules, one per NetBird resource type |
| `terragrunt/netbird-live/` | Terragrunt units that apply those modules to a NetBird instance |
| `terragrunt/infrastructure-modules/`, `terragrunt/infrastructure-live/` | AWS infrastructure (VPC, EKS, IAM, ...) |
| `services/infra/core/` | Helm charts for NetBird, CloudNativePG, External Secrets, AWS LB Controller |
| `docs/` | Architecture and operations notes |

## Making a change to a module

1. Edit the module and its `README.md` (inputs, outputs, examples).
2. Add or update tests in `<module>/tests/*.tftest.hcl`. Tests use `mock_provider`, so they run
   without a NetBird server:
   ```sh
   cd netbird-terraform/modules/<module>
   terraform init -backend=false && terraform validate && terraform test
   ```
3. Run `pre-commit run --all-files`.
4. If you have a NetBird instance, run `terragrunt plan` in the matching unit under
   `terragrunt/netbird-live/` and include the (redacted) plan summary in the PR.
5. Add a line to `CHANGELOG.md` under **Unreleased**.

## Running against a NetBird instance

```sh
export NB_PAT=<admin personal access token>     # never write it to a file in the repo
cd terragrunt/netbird-live/accounts/<account>/<env>
terragrunt run --all plan
```

A pre-flight hook checks the token first: NetBird answers an invalid token with HTTP 404, which
the provider would otherwise read as "every resource was deleted".

## Commit messages

Use short imperative subjects, optionally prefixed with the area:
`policy: support port ranges`, `ci: cache provider plugins`.
