# NetBird SCIM Integration Module

Manages the account-wide SCIM directory synchronization provider (`netbird_scim`).

## Architecture
- **Type**: Singleton
- **Resource**: `netbird_scim`

## Security Considerations
- `auth_token` is the generated SCIM API bearer token.
- `output.auth_token` and `output.scim` are marked `sensitive = true`.
- Non-sensitive metadata (`id`, `provider_name`, `enabled`, `last_synced_at`) are exported separately.

## Inputs

| Name | Type | Description | Default |
|------|------|-------------|---------|
| `provider_name` | `string` | Name of SCIM IdP (e.g. `"keycloak"`, `"okta"`, `"azure-ad"`) | - |
| `enabled` | `bool` | Whether the integration is active | `true` |
| `prefix` | `string` | Connection prefix used for SCIM provider | `null` |
| `group_prefixes` | `list(string)` | Prefix filter patterns for groups to synchronize | `null` |
| `user_group_prefixes` | `list(string)` | Prefix filter patterns for user groups | `null` |

## Outputs

| Name | Sensitive | Description |
|------|:---------:|-------------|
| `id` | No | SCIM integration ID |
| `provider_name` | No | Provider name |
| `enabled` | No | Enabled status |
| `last_synced_at` | No | Last sync timestamp |
| `auth_token` | **Yes** | Sensitive SCIM bearer token |

## Example Usage

```hcl
module "scim" {
  source = "../../modules/scim"

  provider_name = "keycloak"
  enabled       = true
}
```
