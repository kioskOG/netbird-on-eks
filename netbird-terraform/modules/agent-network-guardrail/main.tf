resource "netbird_agent_network_guardrail" "this" {
  for_each = var.items

  description     = each.value.description
  model_allowlist = each.value.model_allowlist
  name            = each.value.name
  prompt_capture  = each.value.prompt_capture
}
