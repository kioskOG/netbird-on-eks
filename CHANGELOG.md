# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- Offline `terraform test` suites (mocked provider) for the group, policy, setup-key, dns-record,
  user, peer, identity-provider and reverse-proxy-service modules.
- CI: gitleaks, `terraform fmt`/`validate`/`test`, `terragrunt hcl format`, `helm lint`, ShellCheck.
- pre-commit configuration, Dependabot, issue and pull request templates.
- CONTRIBUTING, SECURITY and CODE_OF_CONDUCT documents.
- Terragrunt pre-flight hook that refuses to plan/apply when `NB_PAT` is missing or rejected.
- Setup-key module docs on key expiry and rotation.
- `REPLACE_ME_<NAME>` placeholders for every environment-specific value (AWS account ID, region,
  VPC ID, domain, ACM certificate, IAM roles, Keycloak credentials). Real values live in gitignored
  `*.local.yaml` / `.envrc.local` overrides layered on top by Helm (`-f values.local.yaml`) and by
  the Terragrunt YAML loaders.
- `scripts/placeholders.py` (`init`, `check`, `docs`) and the generated `PLACEHOLDERS.md`.

### Changed
- NetBird provider constraint raised to `~> 0.0.11`; lock files regenerated for
  darwin/linux on amd64 and arm64.
- Terraform 1.16.5 and Terragrunt 1.1.6 pinned via `.terraform-version` / `.terragrunt-version`.
- Plugin-cache configuration in `netbird-live/root.hcl` consolidated into one block.
- `infrastructure-live`: removed `common.tfvars` (its only value, `region`, was already supplied
  as `TF_VAR_region` from `env.yaml`); availability zones derived from the region.
- Domain, peer name and IAM role names are read from YAML instead of being hardcoded in units.
- `create-netbird-token-to-secretsmanager.sh` requires `NB_MANAGEMENT_URL` / `--url` (no default).
- `.terraform-version` / `.terragrunt-version` moved to `terragrunt/` so both stacks use them.

### Fixed
- First `init` on a fresh checkout failed because the plugin cache directory did not exist.

### Security
- Removed a committed TLS private key, certificate and NetBird PAT; hardened `.gitignore`.
