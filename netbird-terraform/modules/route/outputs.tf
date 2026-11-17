output "route_ids" {
  description = "Map of route keys to IDs"
  value       = { for k, v in netbird_route.this : k => v.id }
}
