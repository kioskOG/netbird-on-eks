output "user_ids" {
  description = "Map of user keys to IDs"
  value       = { for k, v in netbird_user.this : k => v.id }
}

output "email_to_id" {
  description = "Map of user emails to IDs"
  value       = { for k, v in netbird_user.this : v.email => v.id if v.email != null }
}

output "name_to_id" {
  description = "Map of user names to IDs"
  value       = { for k, v in netbird_user.this : v.name => v.id if v.name != null }
}
