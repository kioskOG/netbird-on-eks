# NetBird Network Router Module

Manages network routing peers (`netbird_network_router`) for a NetBird virtual network.

## Architecture
- **Type**: Collection (`var.items`)
- **Resource**: `netbird_network_router`

## Inputs

| Name | Type | Description | Default |
|------|------|-------------|---------|
| `network_id` | `string` | Optional default network ID for all items | `null` |
| `items` | `map(object)` | Map of network router definitions | `{}` |

### Item Attributes

- `network_id` (`string`, optional): Network ID (or inherited from module level).
- `peer` (`string`, optional): Specific routing peer ID.
- `peer_groups` (`list(string)`, optional): Peer group IDs providing high-availability routing.
- `masquerade` (`bool`, optional): Enable NAT masquerade.
- `metric` (`number`, optional): Route metric priority.
- `enabled` (`bool`, optional): Whether the router is enabled.

## Outputs

| Name | Description |
|------|-------------|
| `network_router_ids` | Map of router keys to IDs |

## Example Usage

```hcl
module "network_routers" {
  source     = "../../modules/network-router"
  network_id = module.network.network_ids["default"]

  items = {
    "router1" = {
      peer_groups = [module.groups.group_ids["routers"]]
      masquerade  = true
      metric      = 100
    }
  }
}
```
