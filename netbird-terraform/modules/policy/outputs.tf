output "policy_ids" {
  description = "Map of policy keys to IDs"
  value       = { for k, v in netbird_policy.this : k => v.id }
}

output "name_to_id" {
  description = "Map of policy names to IDs"
  value       = { for k, v in netbird_policy.this : v.name => v.id }
}
