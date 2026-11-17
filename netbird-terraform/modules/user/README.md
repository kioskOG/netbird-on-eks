# NetBird User Module

Manages regular and service users (`netbird_user`) in NetBird.

## Architecture
- **Type**: Collection (`var.items`)
- **Resource**: `netbird_user`

## Inputs

| Name | Type | Description | Default |
|------|------|-------------|---------|
| `items` | `map(object)` | Map of user definitions | `{}` |

### Item Attributes

- `is_service_user` (`bool`, required): Whether this is a service user (bot/automation) or regular user.
- `name` (`string`, optional): User name (required for service users).
- `email` (`string`, optional): Email address (for regular users).
- `role` (`string`, optional): User role (`"owner"`, `"admin"`, `"user"`, `"auditor"`, `"network_admin"`).
- `auto_groups` (`list(string)`, optional): Group IDs assigned automatically to peers enrolled by this user.
- `is_blocked` (`bool`, optional): Whether the user is blocked.

## Outputs

| Name | Description |
|------|-------------|
| `user_ids` | Map of user keys to IDs |
| `email_to_id` | Map of user emails to IDs |
| `name_to_id` | Map of user names to IDs |

## Example Usage

```hcl
module "users" {
  source = "../../modules/user"

  items = {
    "ci_bot" = {
      is_service_user = true
      name            = "ci-automation-bot"
      role            = "admin"
      auto_groups     = [module.groups.group_ids["servers"]]
    }
  }
}
```
