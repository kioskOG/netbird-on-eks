# NetBird Nameserver Group Module

Manages upstream DNS resolver configurations (`netbird_nameserver_group`) assigned to specific NetBird groups.

## Architecture
- **Type**: Collection (`var.items`)
- **Resource**: `netbird_nameserver_group`

## Inputs

| Name | Type | Description | Default |
|------|------|-------------|---------|
| `items` | `map(object)` | Map of nameserver group definitions | `{}` |

### Item Attributes

- `name` (`string`, required): Name of the nameserver group.
- `groups` (`list(string)`, required): List of NetBird group IDs receiving this configuration.
- `nameservers` (`list(object)`, required):
  - `ip` (`string`, required): Nameserver IP address.
  - `ns_type` (`string`, optional): Nameserver type (`"udp"`).
  - `port` (`number`, optional): Port (default 53).
- `domains` (`list(string)`, optional): Match domains for split DNS.
- `primary` (`bool`, optional): Whether this is the primary DNS resolver.
- `search_domains_enabled` (`bool`, optional): Enable search domains forwarding.
- `enabled` (`bool`, optional): Whether the configuration is enabled.

## Outputs

| Name | Description |
|------|-------------|
| `nameserver_group_ids` | Map of group keys to IDs |
| `name_to_id` | Map of group names to IDs |

## Example Usage

```hcl
module "dns_forwarders" {
  source = "../../modules/nameserver-group"

  items = {
    "cloudflare" = {
      name    = "Cloudflare DNS"
      groups  = [module.groups.group_ids["all"]]
      primary = true
      nameservers = [
        { ip = "1.1.1.1", port = 53 },
        { ip = "1.0.0.1", port = 53 }
      ]
    }
  }
}
```
