# NetBird Agent Network Guardrail Module

Manages `netbird_agent_network_guardrail` resources for AI agent proxy governance, model filtering, and prompt capture.

## Architecture
- **Type**: Collection (`var.items`)
- **Resource**: `netbird_agent_network_guardrail`

## Inputs

| Name | Type | Description | Default |
|------|------|-------------|---------|
| `items` | `map(object)` | Map of guardrail definitions | `{}` |

### Item Attributes

- `name` (`string`, required): Name of the guardrail.
- `description` (`string`, optional): Guardrail description.
- `model_allowlist` (`object`, required):
  - `models` (`list(string)`, required): Allowed model IDs (e.g. `["gpt-4o", "claude-3-5-sonnet"]`).
  - `enabled` (`bool`, optional): Whether model filtering is active.
- `prompt_capture` (`object`, required):
  - `enabled` (`bool`, optional): Enable prompt logging.
  - `redact_pii` (`bool`, optional): Redact PII from captured prompts.

## Outputs

| Name | Description |
|------|-------------|
| `agent_network_guardrail_ids` | Map of guardrail keys to IDs |
| `name_to_id` | Map of guardrail names to IDs |

## Example Usage

```hcl
module "guardrails" {
  source = "../../modules/agent-network-guardrail"

  items = {
    "strict" = {
      name        = "strict-guardrail"
      description = "Strict LLM filtering with PII redaction"
      model_allowlist = {
        enabled = true
        models  = ["gpt-4o-mini", "claude-3-haiku"]
      }
      prompt_capture = {
        enabled    = true
        redact_pii = true
      }
    }
  }
}
```
