# NetBird DNS Record Module

Manages internal NetBird mesh DNS records (`netbird_dns_record`) within a private DNS zone.

## Architecture
- **Type**: Collection (`var.items`)
- **Resource**: `netbird_dns_record`

> [!NOTE]
> This module manages NetBird MagicDNS / mesh records, NOT AWS Route53 records.

## Inputs

| Name | Type | Description | Default |
|------|------|-------------|---------|
| `items` | `map(object)` | Map of DNS record definitions | `{}` |

### Item Attributes

- `zone_id` (`string`, required): Target DNS zone ID.
- `name` (`string`, required): Record host name (relative to zone domain).
- `type` (`string`, required): Record type (`"A"`, `"AAAA"`, `"CNAME"`, `"TXT"`, etc.).
- `content` (`string`, required): Record target value / IP address.
- `ttl` (`number`, optional): TTL in seconds.

## Outputs

| Name | Description |
|------|-------------|
| `dns_record_ids` | Map of record keys to IDs |

## Example Usage

```hcl
module "dns_records" {
  source = "../../modules/dns-record"

  items = {
    "db" = {
      zone_id = module.dns_zones.dns_zone_ids["corp"]
      name    = "postgres"
      type    = "A"
      content = "100.64.0.10"
      ttl     = 300
    }
  }
}
```
