# NetBird Network Module

Manages virtual network topologies (`netbird_network`) within NetBird.

## Architecture
- **Type**: Collection (`var.items`)
- **Resource**: `netbird_network`

## Inputs

| Name | Type | Description | Default |
|------|------|-------------|---------|
| `items` | `map(object)` | Map of network definitions | `{}` |

### Item Attributes

- `name` (`string`, required): Network name.
- `description` (`string`, optional): Network description.

## Outputs

| Name | Description |
|------|-------------|
| `network_ids` | Map of network keys to IDs |
| `name_to_id` | Map of network names to IDs |

## Example Usage

```hcl
module "network" {
  source = "../../modules/network"

  items = {
    "default" = {
      name        = "main-mesh"
      description = "Primary corporate mesh network"
    }
  }
}
```
