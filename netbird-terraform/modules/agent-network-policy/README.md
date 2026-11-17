# NetBird Agent Network Policy Module

Manages `netbird_agent_network_policy` resources controlling access from peer groups to AI providers, spend caps, and token limits.

## Architecture
- **Type**: Collection (`var.items`)
- **Resource**: `netbird_agent_network_policy`

## Inputs

| Name | Type | Description | Default |
|------|------|-------------|---------|
| `items` | `map(object)` | Map of policy definitions | `{}` |

### Item Attributes

- `name` (`string`, required): Policy name.
- `destination_provider_ids` (`list(string)`, required): List of agent network provider IDs.
- `source_groups` (`list(string)`, required): List of source NetBird group IDs.
- `description` (`string`, optional): Policy description.
- `enabled` (`bool`, optional): Whether the policy is enabled.
- `guardrail_ids` (`list(string)`, optional): Associated guardrail IDs.
- `budget_limit` (`object`, optional): Per-window USD spend caps (`group_cap_usd`, `user_cap_usd`, `window_seconds`, `enabled`).
- `token_limit` (`object`, optional): Per-window token caps (`group_cap`, `user_cap`, `window_seconds`, `enabled`).

## Outputs

| Name | Description |
|------|-------------|
| `agent_network_policy_ids` | Map of policy keys to IDs |
| `name_to_id` | Map of policy names to IDs |

## Example Usage

```hcl
module "agent_policies" {
  source = "../../modules/agent-network-policy"

  items = {
    "engineers" = {
      name                     = "engineers-llm-access"
      source_groups            = [module.groups.group_ids["engineers"]]
      destination_provider_ids = [module.providers.agent_network_provider_ids["openai"]]
      guardrail_ids            = [module.guardrails.agent_network_guardrail_ids["strict"]]
      budget_limit = {
        enabled        = true
        user_cap_usd   = 50
        window_seconds = 86400
      }
    }
  }
}
```
