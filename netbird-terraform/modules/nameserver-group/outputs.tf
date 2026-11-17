output "nameserver_group_ids" {
  description = "Map of nameserver group keys to IDs"
  value       = { for k, v in netbird_nameserver_group.this : k => v.id }
}

output "name_to_id" {
  description = "Map of nameserver group names to IDs"
  value       = { for k, v in netbird_nameserver_group.this : v.name => v.id }
}
