output "agent_network_guardrail_ids" {
  description = "Map of guardrail keys to IDs"
  value       = { for k, v in netbird_agent_network_guardrail.this : k => v.id }
}

output "name_to_id" {
  description = "Map of guardrail names to IDs"
  value       = { for k, v in netbird_agent_network_guardrail.this : v.name => v.id }
}
