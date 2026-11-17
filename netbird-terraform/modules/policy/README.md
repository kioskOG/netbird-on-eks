# NetBird Policy Module

Manages access control and firewall policies (`netbird_policy`), specifying rules, ports, protocols, and posture checks.

## Architecture
- **Type**: Collection (`var.items`)
- **Resource**: `netbird_policy`

## Inputs

| Name | Type | Description | Default |
|------|------|-------------|---------|
| `items` | `map(object)` | Map of policy definitions | `{}` |

### Item Attributes

- `name` (`string`, required): Policy name.
- `description` (`string`, optional): Policy description.
- `enabled` (`bool`, optional): Whether policy is active.
- `source_posture_checks` (`list(string)`, optional): Posture check IDs required for sources.
- `rule` (`list(object)`, optional): List of policy rules:
  - `name` (`string`, required): Rule name.
  - `action` (`string`, optional): `"accept"` or `"drop"`.
  - `bidirectional` (`bool`, optional): Bidirectional flow.
  - `protocol` (`string`, optional): `"tcp"`, `"udp"`, `"icmp"`, `"all"`, or `"netbird-ssh"`.
  - `sources` (`list(string)`, optional): Source group IDs.
  - `source_resource` (`object({ id = string, type = string })`, optional): Source network resource.
  - `destinations` (`list(string)`, optional): Destination group IDs.
  - `destination_resource` (`object({ id = string, type = string })`, optional): Destination network resource.
  - `ports` (`list(string)`, optional): Discrete ports (e.g. `["80", "443"]`).
  - `port_ranges` (`list(object({ start = number, end = number }))`, optional): Port ranges.
  - `authorized_groups` (`map(list(string))`, optional): Group-to-users authorization map for SSH.

## Outputs

| Name | Description |
|------|-------------|
| `policy_ids` | Map of policy keys to IDs |
| `name_to_id` | Map of policy names to IDs |

## Example Usage

```hcl
module "policies" {
  source = "../../modules/policy"

  items = {
    "web_access" = {
      name        = "allow-web-traffic"
      description = "Allow developers to access web servers"
      enabled     = true
      rule = [
        {
          name          = "http-https"
          action        = "accept"
          protocol      = "tcp"
          bidirectional = true
          sources       = [module.groups.group_ids["devs"]]
          destinations  = [module.groups.group_ids["servers"]]
          ports         = ["80", "443"]
        }
      ]
    }
  }
}
```
