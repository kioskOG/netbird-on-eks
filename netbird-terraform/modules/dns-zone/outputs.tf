output "dns_zone_ids" {
  description = "Map of DNS zone keys to IDs"
  value       = { for k, v in netbird_dns_zone.this : k => v.id }
}

output "name_to_id" {
  description = "Map of DNS zone names to IDs"
  value       = { for k, v in netbird_dns_zone.this : v.name => v.id }
}

output "domain_to_id" {
  description = "Map of DNS zone domains to IDs"
  value       = { for k, v in netbird_dns_zone.this : v.domain => v.id }
}
