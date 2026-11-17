output "token_ids" {
  description = "Map of token keys to IDs"
  value       = { for k, v in netbird_token.this : k => v.id }
}

output "token_metadata" {
  description = "Non-sensitive metadata for created tokens"
  value = {
    for k, v in netbird_token.this : k => {
      id              = v.id
      name            = v.name
      user_id         = v.user_id
      expiration_date = v.expiration_date
      created_at      = v.created_at
      last_used       = v.last_used
    }
  }
}

output "name_to_id" {
  description = "Map of token names to IDs"
  value       = { for k, v in netbird_token.this : v.name => v.id }
}

output "tokens" {
  description = "Map of token keys to plaintext sensitive Personal Access Tokens (PATs)"
  value       = { for k, v in netbird_token.this : k => v.token }
  sensitive   = true
}
