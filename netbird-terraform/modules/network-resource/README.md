# NetBird Network Resource Module

Manages network resource endpoints (`netbird_network_resource`) attached to a NetBird virtual network.

## Architecture
- **Type**: Collection (`var.items`)
- **Resource**: `netbird_network_resource`

## Network ID Inheritance
A module-level `network_id` variable can be supplied to default all items in this module, or overridden per-item:
`network_id = coalesce(each.value.network_id, var.network_id)`

## Inputs

| Name | Type | Description | Default |
|------|------|-------------|---------|
| `network_id` | `string` | Optional default network ID for all items | `null` |
| `items` | `map(object)` | Map of network resource definitions | `{}` |

### Item Attributes

- `name` (`string`, required): Resource name.
- `address` (`string`, required): Resource IP, subnet, or domain.
- `groups` (`set(string)`, required): Group IDs allowed to access this resource.
- `network_id` (`string`, optional): Overrides module-level `network_id`.
- `description` (`string`, optional): Resource description.
- `enabled` (`bool`, optional): Whether the resource is enabled.

## Outputs

| Name | Description |
|------|-------------|
| `network_resource_ids` | Map of resource keys to IDs |
| `name_to_id` | Map of resource names to IDs |

## Example Usage

```hcl
module "network_resources" {
  source     = "../../modules/network-resource"
  network_id = module.network.network_ids["default"]

  items = {
    "internal_api" = {
      name    = "internal-api"
      address = "10.0.10.50/32"
      groups  = [module.groups.group_ids["devs"]]
    }
  }
}
```
