resource "netbird_agent_network_policy" "this" {
  for_each = var.items

  budget_limit             = each.value.budget_limit
  description              = each.value.description
  destination_provider_ids = each.value.destination_provider_ids
  enabled                  = each.value.enabled
  guardrail_ids            = each.value.guardrail_ids
  name                     = each.value.name
  source_groups            = each.value.source_groups
  token_limit              = each.value.token_limit
}
