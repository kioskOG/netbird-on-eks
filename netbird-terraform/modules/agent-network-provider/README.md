# NetBird Agent Network Provider Module

Manages `netbird_agent_network_provider` resources connecting upstream LLM APIs into NetBird's agent gateway.

## Architecture
- **Type**: Collection (`var.items`)
- **Resource**: `netbird_agent_network_provider`

## Security Considerations
- `api_key` is marked sensitive by the provider.
- `var.items`, `output.items`, and `output.api_keys` are marked `sensitive = true`.
- Use `agent_network_provider_ids` and `agent_network_provider_metadata` for non-sensitive references.

## Inputs

| Name | Type | Description | Default |
|------|------|-------------|---------|
| `items` | `map(object)` | Map of provider configurations (Sensitive) | `{}` |

### Item Attributes

- `name` (`string`, required): Display name.
- `provider_id` (`string`, required): Unique provider identifier (e.g. `"openai"`).
- `upstream_url` (`string`, required): Target API endpoint URL.
- `api_key` (`string`, required, sensitive): API secret key.
- `enabled` (`bool`, optional): Whether the provider is active.
- `models` (`list(object)`, optional): Pricing catalog (`id`, `input_per_1k`, `output_per_1k`).

## Outputs

| Name | Sensitive | Description |
|------|:---------:|-------------|
| `agent_network_provider_ids` | No | Map of provider keys to IDs |
| `agent_network_provider_metadata` | No | Non-sensitive metadata (names, endpoints, status) |
| `name_to_id` | No | Map of provider names to IDs |

## Example Usage

```hcl
module "providers" {
  source = "../../modules/agent-network-provider"

  items = {
    "openai" = {
      name         = "OpenAI Gateway"
      provider_id  = "openai-main"
      upstream_url = "https://api.openai.com/v1"
      api_key      = var.openai_api_key
      enabled      = true
    }
  }
}
```
