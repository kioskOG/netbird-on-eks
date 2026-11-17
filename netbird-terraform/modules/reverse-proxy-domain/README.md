# NetBird Reverse Proxy Domain Module

Manages public ingress domains (`netbird_reverse_proxy_domain`) for the NetBird reverse proxy gateway.

## Architecture
- **Type**: Collection (`var.items`)
- **Resource**: `netbird_reverse_proxy_domain`

## Inputs

| Name | Type | Description | Default |
|------|------|-------------|---------|
| `items` | `map(object)` | Map of proxy domain definitions | `{}` |

### Item Attributes

- `domain` (`string`, required): Fully qualified domain name.
- `target_cluster` (`string`, required): Proxy ingress cluster ID handling this domain.

## Outputs

| Name | Description |
|------|-------------|
| `reverse_proxy_domain_ids` | Map of domain keys to IDs |
| `domain_to_id` | Map of FQDN domains to IDs |

## Example Usage

```hcl
module "proxy_domains" {
  source = "../../modules/reverse-proxy-domain"

  items = {
    "app" = {
      domain         = "app.vpn.example.com"
      target_cluster = "default-cluster"
    }
  }
}
```
