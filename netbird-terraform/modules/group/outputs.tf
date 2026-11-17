output "group_ids" {
  description = "Map of group keys to IDs"
  value       = { for k, v in netbird_group.this : k => v.id }
}

output "name_to_id" {
  description = "Map of group names to NetBird group IDs"
  value       = { for k, v in netbird_group.this : v.name => v.id }
}
