output "id" {
  description = "The unique identifier of the NetBird account"
  value       = netbird_account_settings.this.id
}

output "account_id" {
  description = "The unique identifier of the NetBird account (alias for id)"
  value       = netbird_account_settings.this.id
}

