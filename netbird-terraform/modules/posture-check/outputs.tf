output "posture_check_ids" {
  description = "Map of posture check keys to IDs"
  value       = { for k, v in netbird_posture_check.this : k => v.id }
}

output "name_to_id" {
  description = "Map of posture check names to IDs"
  value       = { for k, v in netbird_posture_check.this : v.name => v.id }
}
