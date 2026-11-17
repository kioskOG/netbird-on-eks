# NetBird Terraform Module Library

This directory provides an enterprise-ready, production-grade reusable Terraform module library for managing resources in a NetBird environment using the `netbirdio/netbird` Terraform provider.

## Provider Specification
- **Provider**: `registry.terraform.io/netbirdio/netbird`
- **Version Constraint**: `~> 0.0.10`
- **Terraform Compatibility**: `>= 1.5.0` (validated against Terraform `1.16.5`)

---

## Architecture Overview

The library provides complete coverage of all 24 resources available in provider v0.0.10, partitioned cleanly into **Singleton** and **Collection** modules based on NetBird API semantics:

```
netbird-terraform/
├── README.md
├── modules/
│   ├── account-settings/         # [Singleton]  Tenant account configuration
│   ├── agent-network-guardrail/  # [Collection] AI proxy model filters & PII redaction
│   ├── agent-network-policy/     # [Collection] AI proxy routing & spend limits
│   ├── agent-network-provider/   # [Collection] AI/LLM upstream providers (Sensitive)
│   ├── agent-network-settings/   # [Singleton]  AI gateway global settings
│   ├── dns-record/               # [Collection] Mesh MagicDNS records (with zone_id inheritance)
│   ├── dns-settings/             # [Singleton]  Account-wide DNS settings
│   ├── dns-zone/                 # [Collection] Mesh MagicDNS zones
│   ├── group/                    # [Collection] Access boundary & service groups
│   ├── identity-provider/        # [Singleton]  OAuth2/OIDC IdP (Keycloak SSO, Sensitive)
│   ├── nameserver-group/         # [Collection] Split DNS forwarders
│   ├── network/                  # [Collection] Virtual network topologies
│   ├── network-resource/         # [Collection] Endpoints in a network (network_id inheritance)
│   ├── network-router/           # [Collection] Gateway routers in a network (network_id inheritance)
│   ├── peer/                     # [Collection] Server-side peer governance & metadata
│   ├── policy/                   # [Collection] Access control & firewall rules
│   ├── posture-check/            # [Collection] Device compliance checks (5 nested checks)
│   ├── reverse-proxy-domain/     # [Collection] Ingress proxy domains
│   ├── reverse-proxy-service/    # [Collection] Ingress L7/L4 services (Sensitive)
│   ├── route/                    # [Collection] Legacy Network Routes (network_id = route identifier)
│   ├── scim/                     # [Singleton]  Directory synchronization (Sensitive)
│   ├── setup-key/                # [Collection] Device enrollment keys (Sensitive)
│   ├── token/                    # [Collection] Personal Access Tokens (Sensitive)
│   └── user/                     # [Collection] Regular & service users
```

---

## Mandatory Resource Naming Standards

All NetBird resources managed by this library follow strict platform naming conventions:

| Resource Type | Naming Pattern | Production Examples |
|---|---|---|
| **Peers** | `peer-<team>-<env>` | `peer-devops-prod`, `peer-support-prod` |
| **Services / Groups** | `svc-<app>-<tier>-<env>` | `svc-orders-web-prod`, `svc-orders-db-prod` |
| **Networks** | `net-<provider>-<region>-<env>` | `net-aws-use2-prod`, `net-aws-euc1-prod` |
| **Policies** | `<source> -> <dest> [<protocol>/<port>]` | `peer-devops-prod -> svc-orders-web-prod [TCP/443]` |
| **Setup Keys** | `setup-<env>-<purpose>` | `setup-prod-servers`, `setup-dev-monitoring` |

*Note: Environment contexts (`prod`, `dev`, `use2`) are not hardcoded inside the reusable modules; they are passed in by the caller or derived by the live/Terragrunt layer.*

---

## Module Paradigms

### 1. Singleton Modules (5 Resources)
Resources that represent global, account-wide, or single-integration configurations are implemented as **singletons** with flat root inputs and singular outputs:
- **`account-settings`**: Account expiration, JWT claims, and peer approval.
- **`dns-settings`**: Account-wide DNS resolver disabled management groups.
- **`agent-network-settings`**: Global AI gateway endpoint and retention policies.
- **`scim`**: Tenant SCIM directory integration.
- **`identity-provider`**: Primary OIDC identity provider integration (e.g., Keycloak).

Example Singleton Usage:
```hcl
module "account_settings" {
  source = "../../modules/account-settings"

  peer_login_expiration_enabled = true
  peer_login_expiration         = 86400
}
```

### 2. Collection Modules (19 Resources)
Multi-instance resources accept an `items` map of strongly typed objects and manage resources via `for_each`:
- Accept `items = map(object(...))` with strict type definitions and input validation.
- Export clean, intentional outputs: `<resource>_ids` (map of input keys to IDs), `name_to_id` (map of human-readable names to IDs), and resource-specific lookups.
- Avoid raw generic `items` outputs to prevent exposing internal provider state.

Example Collection Usage:
```hcl
module "groups" {
  source = "../../modules/group"

  items = {
    "orders_web" = {
      name = "svc-orders-web-prod"
    }
    "devops_peers" = {
      name = "peer-devops-prod"
    }
  }
}
```

### 3. Parent ID Inheritance
For closely-coupled resource families, child modules accept an optional top-level ID variable that automatically defaults all child items while still permitting per-item overrides:
- **`network-resource`**, **`network-router`**: accept optional `network_id` (a `netbird_network` ID)
- **`dns-record`**: accepts optional `zone_id`
- **`route`** also accepts a module-level `network_id`, but there it is the legacy route's free-form
  "Network Identifier" (1-40 chars), not a `netbird_network` ID.

```hcl
module "network_resources" {
  source     = "../../modules/network-resource"
  network_id = module.network.network_ids["aws_use2"]

  items = {
    "db" = {
      name    = "svc-orders-db-prod"
      address = "10.36.48.15/32"
      groups  = [module.groups.group_ids["orders_db"]]
    }
  }
}
```

---

## Security & Sensitive Data Architecture

1. **Intentional Outputs Only**:
   Generic `output "items" { value = resource.this }` has been deliberately eliminated across all modules. This ensures sensitive provider attributes cannot leak into root outputs or state exports.
2. **Secret-Bearing Resources**:
   - `identity-provider`: `client_secret` is marked `sensitive = true` and is not re-exported in outputs.
   - `agent-network-provider`: upstream `api_key` is marked sensitive by provider schema and is omitted from outputs. Only non-sensitive metadata (`agent_network_provider_metadata`) is returned.
   - `reverse-proxy-service`: auth credentials (header tokens, passwords, PINs) and custom headers are never echoed in outputs.
   - `setup-key`: plaintext enrollment keys are exported only through an explicitly marked `sensitive = true` output (`setup_keys`), alongside safe non-sensitive metadata (`setup_key_metadata`).
   - `token`: Personal Access Tokens are exported only through an explicitly marked `sensitive = true` output (`tokens`), alongside safe non-sensitive metadata (`token_metadata`).
   - `scim`: Bearer token is exported only via `auth_token` marked `sensitive = true`.
3. **No Hardcoded Credentials**:
   Zero secrets or account tokens are embedded in module definitions, examples, or committed configurations.

---

## Provider Ownership

Child modules **never** configure the NetBird provider inline:
- No `provider "netbird" {}` inside child modules.
- Reusable modules declare required providers and version constraints (`~> 0.0.10`).
- Provider authentication and endpoint configuration (`management_url`, `token`) remain strictly externalized, to be supplied by the root orchestration or Terragrunt layer.

---

## Validation

There is no automated test suite in this repository yet. Each module is checked with:

```bash
terraform fmt -check -recursive netbird-terraform/modules
# per module, against provider netbirdio/netbird 0.0.10
terraform -chdir=netbird-terraform/modules/<module> init -backend=false
terraform -chdir=netbird-terraform/modules/<module> validate
```

`validate` checks attribute names and types against the provider schema. It does not evaluate inputs, so
`variable` validation rules and live-unit wiring (dependency output names, mock outputs) are only exercised
by `terragrunt plan` in the live units.
