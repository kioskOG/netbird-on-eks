# NetBird Terragrunt Architecture Discovery

**Date**: 2026-10-08  
**Repository**: `kioskOG/netbird-on-eks`  
**Scope**: Reverse-engineering existing repository Terragrunt and Terraform patterns to establish conventions for the dedicated NetBird live layer.

---

## 1. Executive Context

The repository contains an existing, production AWS infrastructure managed via Terragrunt under `terragrunt/infrastructure-live/` and reusable modules under `terragrunt/infrastructure-modules/`. In addition, NetBird v0.80.0 server components run on EKS, deployed via Helm charts under `services/infra/core/netbird/dev/`.

Before implementing the dedicated NetBird Terragrunt/live layer (`terragrunt/netbird-live/`), this discovery audit extracts the exact repository conventions for remote state, provider generation, environment hierarchy, dependency wiring, secret isolation, and module consumption.

---

## 2. Findings by Rigor Category

### VERIFIED (Facts Directly Observed in the Repository)

1. **Terragrunt & Terraform Baselines**:
   - `terragrunt version`: `v1.1.6` (confirmed via CLI execution).
   - `terraform version`: `v1.16.5` (confirmed via CLI execution).
   - Versions pinned in `config/versions.yaml`: `terraform: 1.16.5`, `terragrunt: 1.1.6`, `netbird.provider: 0.0.10`, `netbird.server: v0.80.0`.

2. **Existing Live Root Architecture (`terragrunt/infrastructure-live/root.hcl`)**:
   - **Download Cache**: Centralized via `download_dir = "${get_parent_terragrunt_dir()}/.terragrunt-cache"`.
   - **Hierarchy & Variable Resolution**:
     - `env_vars = yamldecode(file(find_in_parent_folders("env.yaml")))`.
     - `find_in_parent_folders("common.tfvars")` and `common.yaml` supply regional and account-level locals.
   - **Remote State Backend**:
     - Backend: AWS S3 (`backend = "s3"`).
     - Bucket name pattern: `${local.env_vars.aws_account_name}-${local.env_vars.env_name}-terraform-state`.
     - State key pattern: `${local.env_vars.aws_account_id}/${path_relative_to_include()}/terraform.tfstate`.
     - Encryption: `encrypt = true`.
     - State locking: `use_lockfile = true` (Terraform 1.10+ native S3 lockfile; DynamoDB table is not required).
     - Standard S3 bucket tagging: `Org: SystemEngg`, `Team: DevOps`, `Stage: dev`, `Attributes: infra-base`.
   - **Extra Arguments**:
     - `-lock-timeout=1m`, `-input=false`, `-no-color`.
     - Shared plugin caching: `TF_PLUGIN_CACHE_DIR` and `TERRAGRUNT_PLUGIN_CACHE_DIR` set to `${get_parent_terragrunt_dir()}/.terraform.d/plugin-cache`.

3. **Existing AWS Child Unit Structure**:
   - Each directory represents a single deployable unit containing a `terragrunt.hcl`.
   - Includes root include: `include { path = find_in_parent_folders("root.hcl") }`.
   - Module sources use relative paths with double-slash notation: `terraform { source = "../../../../..//infrastructure-modules/<module>" }`.
   - Cross-unit dependencies use `dependency "<name>" { config_path = "..." mock_outputs = { ... } }`.
   - Mock outputs are defined for plan-time execution without live upstream applies.

4. **NetBird Provider v0.0.10 Schema**:
   - Verified directly from provider schema dump (`provider_schema.json`):
     - Endpoint attribute is **`management_url`** (type: string, optional), NOT `api_url`. Environment variable fallback: **`NB_MANAGEMENT_URL`**.
     - Authentication token attribute is **`token`** (type: string, optional, sensitive), NOT `pat` or `api_token`. Environment variable fallback: **`NB_PAT`**.
     - Account impersonation attribute is **`tenant_account`** (type: string, optional). Environment variable fallback: **`NB_ACCOUNT`**.
   - Public endpoint currently reachable: `https://netbird.REPLACE_ME_DOMAIN`.

5. **Existing NetBird EKS & Keycloak Architecture**:
   - Helm chart: `services/infra/core/netbird/dev/` runs NetBird 0.80.0 server and dashboard.
   - Keycloak IdP integration is currently managed via a Kubernetes batch job hook: `templates/idp-sync.yaml` (invoking `sync.py` against `http://netbird-server.dev.svc.cluster.local/api/identity-providers`).
   - Secrets are synchronized into Kubernetes via External Secrets Operator (`templates/external-secret.yaml` pulling from AWS Secrets Manager).

6. **Reusable Module Library (`netbird-terraform/modules/`)**:
   - Complete library of 24 child modules implemented, formatted, and strictly typed.
   - Zero untyped `any`.
   - Zero embedded provider configurations (`provider "netbird" {}` is omitted from child modules).
   - Singleton modules (5): `account-settings`, `dns-settings`, `agent-network-settings`, `scim`, `identity-provider`.
   - Collection modules (19): accept `items = map(object(...))` and export clean lookup maps (`ids`, `name_to_id`).
   - `netbird_peer` requires `id` as an input; it governs existing peers rather than provisioning new machines.

---

### INFERRED (Reasonable Conclusions Based on Repository Conventions)

1. **Dedicated Live Root Location (`terragrunt/netbird-live/`)**:
   - Colocating NetBird live inside `terragrunt/` alongside `infrastructure-live/` (`terragrunt/infrastructure-live/` for AWS and `terragrunt/netbird-live/` for NetBird) provides logical grouping of all Terragrunt live environments while maintaining 100% decoupling between AWS infrastructure and NetBird mesh configuration.
2. **State Isolation**:
   - Storing NetBird state in the S3 bucket under a dedicated prefix:
     `${local.env_vars.aws_account_id}/netbird/${path_relative_to_include()}/terraform.tfstate`
     guarantees that NetBird mesh states never collide with or overwrite AWS infrastructure states (`us-east-2/vpc/...`).
3. **Provider Generation via Terragrunt**:
   - Provider configuration should be generated at the Terragrunt root level via `generate "provider"`, populating `management_url` from environment locals, while deliberately leaving `token` unconfigured in HCL so the provider reads `NB_PAT` from the operating environment.
4. **Naming Construction Layer**:
   - Following repository conventions, naming formulas (`peer-<team>-<env>`, `svc-<app>-<tier>-<env>`, `net-<provider>-<region>-<env>`, `setup-<env>-<purpose>`) belong in environment locals within the Terragrunt live layer, passing constructed strings into child module `items`.
5. **Dependency Flow**:
   - In NetBird live, dependency ordering must flow:
     `groups` & `networks` ➔ `dns-zones`, `network-routers`, `network-resources` ➔ `routes` ➔ `policies`.

---

### NOT VERIFIED (Requires Live Execution)

1. **Live NetBird API Responses**:
   - Whether the running NetBird server at `https://netbird.REPLACE_ME_DOMAIN` accepts simultaneous updates or experiences race conditions during high-concurrency Terraform applies.
2. **Keycloak OIDC Sync Handover**:
   - The exact behavior if the Helm `idp-sync` job runs concurrently with a Terraform-managed `identity-provider` resource.
3. **Setup Key Plaintext Recovery**:
   - Confirming via live API whether `GET /api/setup-keys` ever returns plaintext keys after initial creation. (Schema indicates computed sensitive, leading to the inference that import will not recover keys).
4. **WireGuard Client Kernel Features**:
   - Whether routing peers in the target environment have Linux kernel IP forwarding enabled to support masquerade routes created by `netbird_route`.
