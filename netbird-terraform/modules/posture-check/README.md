# NetBird Posture Check Module

Manages endpoint device posture checks (`netbird_posture_check`) including geo-location, minimum OS/kernel versions, and running processes.

## Architecture
- **Type**: Collection (`var.items`)
- **Resource**: `netbird_posture_check`

## Inputs

| Name | Type | Description | Default |
|------|------|-------------|---------|
| `items` | `map(object)` | Map of posture check definitions | `{}` |

### Item Attributes

- `name` (`string`, required): Posture check name.
- `description` (`string`, optional): Posture check description.
- `geo_location_check` (`object`, optional):
  - `action` (`string`, optional): `"allow"` or `"deny"`.
  - `locations` (`list(object({ country_code = string, city_name = optional(string) }))`, optional): Geographic locations.
- `netbird_version_check` (`object`, optional):
  - `min_version` (`string`, optional): Minimum client agent version (e.g. `"0.28.0"`).
- `os_version_check` (`object`, optional): Minimum OS and kernel version constraints (`darwin_min_version`, `linux_min_kernel_version`, etc.).
- `peer_network_range_check` (`object`, optional):
  - `action` (`string`, optional): Action (`"allow"` or `"deny"`).
  - `ranges` (`list(string)`, optional): IP CIDR blocks.
- `process_check` (`list(object)`, optional): List of required running processes (`linux_path`, `mac_path`, `windows_path`).

## Outputs

| Name | Description |
|------|-------------|
| `posture_check_ids` | Map of posture check keys to IDs |
| `name_to_id` | Map of posture check names to IDs |

## Example Usage

```hcl
module "posture_checks" {
  source = "../../modules/posture-check"

  items = {
    "corporate_standard" = {
      name        = "corporate-device-compliance"
      description = "Requires minimum NetBird client version and allowed countries"
      netbird_version_check = {
        min_version = "0.28.0"
      }
      geo_location_check = {
        action = "allow"
        locations = [
          { country_code = "US" },
          { country_code = "IN" }
        ]
      }
    }
  }
}
```
