output "id" {
  description = "SCIM integration ID"
  value       = netbird_scim.this.id
}

output "provider_name" {
  description = "Name of the SCIM identity provider"
  value       = netbird_scim.this.provider_name
}

output "enabled" {
  description = "Whether the SCIM integration is enabled"
  value       = netbird_scim.this.enabled
}

output "last_synced_at" {
  description = "Timestamp of when the integration was last synced"
  value       = netbird_scim.this.last_synced_at
}

output "auth_token" {
  description = "SCIM API bearer token (sensitive)"
  value       = netbird_scim.this.auth_token
  sensitive   = true
}

