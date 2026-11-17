output "agent_network_policy_ids" {
  description = "Map of agent network policy keys to IDs"
  value       = { for k, v in netbird_agent_network_policy.this : k => v.id }
}

output "name_to_id" {
  description = "Map of agent network policy names to IDs"
  value       = { for k, v in netbird_agent_network_policy.this : v.name => v.id }
}
