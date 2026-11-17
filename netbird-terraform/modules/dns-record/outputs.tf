output "dns_record_ids" {
  description = "IDs of the created netbird_dns_record resources"
  value       = { for k, v in netbird_dns_record.this : k => v.id }
}

output "name_to_id" {
  description = "Map of DNS record FQDN names to IDs"
  value       = { for k, v in netbird_dns_record.this : v.name => v.id }
}

