# NetBird Setup Key Module

Manages pre-shared device enrollment keys (`netbird_setup_key`) for joining peers to the network.

## Architecture
- **Type**: Collection (`var.items`)
- **Resource**: `netbird_setup_key`

## Security Considerations
- Generated key strings (`netbird_setup_key.key`) are sensitive credentials.
- `output.setup_keys` and `output.items` are marked `sensitive = true`.
- Non-sensitive metadata (`setup_key_ids`, `setup_key_metadata`, `name_to_id`) are exported separately.

## Key expiry and rotation

NetBird marks a key `expired` once `expiry_seconds` has passed, but nothing in the key's
configuration changes, so `terraform plan` reports **no changes** for an expired key. Peers that
already enrolled keep working; only new enrollments fail.

Check the `setup_key_metadata` output (`state` / `valid`) and rotate expired keys by replacing them:

```sh
terragrunt apply -replace='netbird_setup_key.this["<item_key>"]'
```

Rotation creates a new key value, so update every place that consumes it (user data, Helm values,
Secrets Manager).

## Inputs

| Name | Type | Description | Default |
|------|------|-------------|---------|
| `items` | `map(object)` | Map of setup key definitions | `{}` |

### Item Attributes

- `name` (`string`, required): Name/description for the setup key.
- `type` (`string`, optional): Key type (`"reusable"` or `"one-off"`).
- `expiry_seconds` (`number`, optional): Expiration time in seconds.
- `auto_groups` (`list(string)`, optional): Group IDs automatically assigned to peers joining with this key.
- `usage_limit` (`number`, optional): Maximum number of times the key can be used.
- `ephemeral` (`bool`, optional): Whether peers are deleted automatically after disconnecting.
- `allow_extra_dns_labels` (`bool`, optional): Allow peers to register custom DNS labels.

## Outputs

| Name | Sensitive | Description |
|------|:---------:|-------------|
| `setup_key_ids` | No | Map of key keys to IDs |
| `setup_key_metadata` | No | Non-sensitive metadata (expiration, usage limits, ephemeral) |
| `name_to_id` | No | Map of key names to IDs |
| `setup_keys` | **Yes** | Map of key keys to plaintext sensitive setup keys |

## Example Usage

```hcl
module "setup_keys" {
  source = "../../modules/setup-key"

  items = {
    "k8s_nodes" = {
      name           = "k8s-nodes-enrollment"
      type           = "reusable"
      expiry_seconds = 2592000 # 30 days
      auto_groups    = [module.groups.group_ids["servers"]]
    }
  }
}
```
