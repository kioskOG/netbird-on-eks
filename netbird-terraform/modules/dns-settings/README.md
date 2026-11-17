# NetBird DNS Settings Module

Manages account-wide DNS configuration (`netbird_dns_settings`).

## Architecture
- **Type**: Singleton
- **Resource**: `netbird_dns_settings`

## Inputs

| Name | Type | Description | Default |
|------|------|-------------|---------|
| `disabled_management_groups` | `list(string)` | Group IDs whose DNS management is disabled | `[]` |

## Outputs

| Name | Description |
|------|-------------|
| `disabled_management_groups` | List of group IDs with disabled DNS management |

## Example Usage

```hcl
module "dns_settings" {
  source = "../../modules/dns-settings"

  disabled_management_groups = []
}
```
