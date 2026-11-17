# NetBird Group Module

Manages NetBird peer and resource groups (`netbird_group`), the primary tagging and access boundary in NetBird.

## Architecture
- **Type**: Collection (`var.items`)
- **Resource**: `netbird_group`

## Inputs

| Name | Type | Description | Default |
|------|------|-------------|---------|
| `items` | `map(object)` | Map of group definitions | `{}` |

### Item Attributes

- `name` (`string`, required): Group name.
- `peers` (`list(string)`, optional): Explicit list of peer IDs in this group.
- `resources` (`list(string)`, optional): Explicit list of resource IDs in this group.

## Outputs

| Name | Description |
|------|-------------|
| `group_ids` | Map of input map keys to NetBird group IDs |
| `name_to_id` | Map of group names to NetBird group IDs |

## Example Usage

```hcl
module "groups" {
  source = "../../modules/group"

  items = {
    "devs" = {
      name = "developers"
    }
    "servers" = {
      name = "prod-servers"
    }
  }
}
```
