output "network_resource_ids" {
  description = "Map of network resource keys to IDs"
  value       = { for k, v in netbird_network_resource.this : k => v.id }
}

output "name_to_id" {
  description = "Map of network resource names to IDs"
  value       = { for k, v in netbird_network_resource.this : v.name => v.id }
}
