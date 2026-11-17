output "network_router_ids" {
  description = "Map of network router keys to IDs"
  value       = { for k, v in netbird_network_router.this : k => v.id }
}
