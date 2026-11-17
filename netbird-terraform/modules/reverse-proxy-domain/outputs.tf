output "reverse_proxy_domain_ids" {
  description = "Map of domain keys to IDs"
  value       = { for k, v in netbird_reverse_proxy_domain.this : k => v.id }
}

output "domain_to_id" {
  description = "Map of domain FQDNs to IDs"
  value       = { for k, v in netbird_reverse_proxy_domain.this : v.domain => v.id }
}
