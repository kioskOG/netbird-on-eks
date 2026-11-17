# NetBird Route Module

Manages network routing rules (`netbird_route`) directing traffic through designated NetBird gateway peers or groups.

## Architecture
- **Type**: Collection (`var.items`)
- **Resource**: `netbird_route`

## Network Identifier
`netbird_route` is a legacy Network Route (dashboard: **Network Routes**). Its `network_id` is the route's
"Network Identifier": a free-form label of 1-40 characters that groups HA routes for the same range. It is
**not** the ID of a `netbird_network`; Networks are managed with the `network`, `network-resource` and
`network-router` modules.

A module-level `network_id` can be supplied as the default for every item, or overridden per item:
`network_id = coalesce(each.value.network_id, var.network_id)`

## Inputs

| Name | Type | Description | Default |
|------|------|-------------|---------|
| `network_id` | `string` | Default route network identifier (1-40 chars) for all items | `null` |
| `items` | `map(object)` | Map of route definitions | `{}` |

### Item Attributes

- `network_id` (`string`, optional): Route network identifier (or inherited from module level).
- `groups` (`list(string)`, required): Distribution group IDs that receive this route.
- `network` (`string`, optional): Destination CIDR range (e.g. `"172.16.0.0/16"`). Mutually exclusive with `domains`.
- `domains` (`list(string)`, optional): Destination domains for domain-based routing.
- `peer` (`string`, optional): Routing gateway peer ID.
- `peer_groups` (`list(string)`, optional): High-availability routing peer group IDs.
- `masquerade` (`bool`, optional): Enable NAT masquerade on routing peer.
- `metric` (`number`, optional): Route metric priority.
- `enabled` (`bool`, optional): Whether route is active.

## Outputs

| Name | Description |
|------|-------------|
| `route_ids` | Map of route keys to IDs |

## Example Usage

```hcl
module "routes" {
  source     = "../../modules/route"
  network_id = "corp-vpc"

  items = {
    "corp_vpc" = {
      network     = "10.100.0.0/16"
      groups      = [module.groups.group_ids["devs"]]
      peer_groups = [module.groups.group_ids["routers"]]
      masquerade  = true
      metric      = 100
    }
  }
}
```
