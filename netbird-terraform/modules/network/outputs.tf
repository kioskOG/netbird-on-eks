output "network_ids" {
  description = "Map of network keys to IDs"
  value       = { for k, v in netbird_network.this : k => v.id }
}

output "name_to_id" {
  description = "Map of network names to IDs"
  value       = { for k, v in netbird_network.this : v.name => v.id }
}
