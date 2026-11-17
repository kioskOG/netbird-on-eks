output "reverse_proxy_service_ids" {
  description = "Map of service keys to IDs"
  value       = { for k, v in netbird_reverse_proxy_service.this : k => v.id }
}

output "reverse_proxy_service_metadata" {
  description = "Map of non-sensitive reverse proxy service metadata"
  value = {
    for k, v in netbird_reverse_proxy_service.this : k => {
      id            = v.id
      name          = v.name
      domain        = v.domain
      enabled       = v.enabled
      mode          = v.mode
      listen_port   = v.listen_port
      proxy_cluster = v.proxy_cluster
    }
  }
}

output "name_to_id" {
  description = "Map of service names to IDs"
  value       = { for k, v in netbird_reverse_proxy_service.this : v.name => v.id }
}

