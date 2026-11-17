output "agent_network_provider_ids" {
  description = "Map of provider keys to IDs"
  value       = { for k, v in netbird_agent_network_provider.this : k => v.id }
}

output "agent_network_provider_metadata" {
  description = "Map of non-sensitive provider metadata"
  value = {
    for k, v in netbird_agent_network_provider.this : k => {
      id           = v.id
      name         = v.name
      provider_id  = v.provider_id
      upstream_url = v.upstream_url
      enabled      = v.enabled
    }
  }
}

output "name_to_id" {
  description = "Map of provider names to IDs"
  value       = { for k, v in netbird_agent_network_provider.this : v.name => v.id }
}

