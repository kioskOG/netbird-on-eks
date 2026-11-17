output "setup_key_ids" {
  description = "Map of setup key keys to IDs"
  value       = { for k, v in netbird_setup_key.this : k => v.id }
}

output "setup_key_metadata" {
  description = "Non-sensitive metadata for created setup keys"
  value = {
    for k, v in netbird_setup_key.this : k => {
      id          = v.id
      name        = v.name
      type        = v.type
      state       = v.state
      expires     = v.expires
      valid       = v.valid
      used_times  = v.used_times
      usage_limit = v.usage_limit
      ephemeral   = v.ephemeral
    }
  }
}

output "name_to_id" {
  description = "Map of setup key names to IDs"
  value       = { for k, v in netbird_setup_key.this : v.name => v.id }
}

output "setup_keys" {
  description = "Map of setup key keys to plaintext sensitive keys"
  value       = { for k, v in netbird_setup_key.this : k => v.key }
  sensitive   = true
}

