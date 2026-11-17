output "id" {
  description = "Identity provider ID"
  value       = netbird_identity_provider.this.id
}

output "name" {
  description = "Human-readable name of the identity provider"
  value       = netbird_identity_provider.this.name
}

output "type" {
  description = "Type of identity provider"
  value       = netbird_identity_provider.this.type
}

output "issuer" {
  description = "OIDC issuer URL"
  value       = netbird_identity_provider.this.issuer
}

output "client_id" {
  description = "OAuth2 client ID"
  value       = netbird_identity_provider.this.client_id
}

