# NetBird Agent Network Settings Module

Manages global account settings for the Agent Network gateway (`netbird_agent_network_settings`).

## Architecture
- **Type**: Singleton
- **Resource**: `netbird_agent_network_settings`

## Inputs

| Name | Type | Description | Default |
|------|------|-------------|---------|
| `access_log_retention_days` | `number` | Retention period in days for access logs | `null` |
| `enable_log_collection` | `bool` | Enable per-request access logging | `null` |
| `enable_prompt_collection` | `bool` | Enable prompt inspection and logging | `null` |
| `endpoint` | `string` | Dedicated hostname agents call for this gateway | `null` |
| `proxy_address` | `string` | Shared proxy cluster address for the gateway | `null` |
| `redact_pii` | `bool` | Globally redact PII from captured prompts | `null` |

## Outputs

| Name | Description |
|------|-------------|
| `dedicated` | Whether a proxy dedicated to this account serves the gateway |
| `endpoint` | Assigned endpoint hostname |
| `proxy_address` | Assigned proxy cluster address |

## Example Usage

```hcl
module "agent_network_settings" {
  source = "../../modules/agent-network-settings"

  enable_log_collection     = true
  enable_prompt_collection  = true
  redact_pii                = true
  access_log_retention_days = 30
}
```
