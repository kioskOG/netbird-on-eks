output "dedicated" {
  description = "Whether a proxy dedicated to this account serves the gateway"
  value       = netbird_agent_network_settings.this.dedicated
}

output "endpoint" {
  description = "Assigned hostname agents call for this account"
  value       = netbird_agent_network_settings.this.endpoint
}

output "proxy_address" {
  description = "Assigned cluster address of the proxy serving this account"
  value       = netbird_agent_network_settings.this.proxy_address
}

