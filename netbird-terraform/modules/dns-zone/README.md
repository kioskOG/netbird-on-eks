# NetBird DNS Zone Module

Manages internal NetBird mesh DNS zones (`netbird_dns_zone`).

## Architecture
- **Type**: Collection (`var.items`)
- **Resource**: `netbird_dns_zone`

## Inputs

| Name | Type | Description | Default |
|------|------|-------------|---------|
| `items` | `map(object)` | Map of DNS zone definitions | `{}` |

### Item Attributes

- `domain` (`string`, required): Zone domain name (e.g. `"internal.net"`).
- `name` (`string`, required): Human-readable zone name.
- `distribution_groups` (`set(string)`, optional): Group IDs to which this zone is distributed.
- `enable_search_domain` (`bool`, optional): Add zone domain to peer search domains.
- `enabled` (`bool`, optional): Whether the zone is enabled.

## Outputs

| Name | Description |
|------|-------------|
| `dns_zone_ids` | Map of zone keys to IDs |
| `name_to_id` | Map of zone names to IDs |
| `domain_to_id` | Map of zone domains to IDs |

## Example Usage

```hcl
module "dns_zones" {
  source = "../../modules/dns-zone"

  items = {
    "corp" = {
      name                 = "Corporate Mesh Zone"
      domain               = "corp.internal"
      enable_search_domain = true
      enabled              = true
    }
  }
}
```
