output "peer_ids" {
  description = "Map of peer keys to peer IDs"
  value       = { for k, v in netbird_peer.this : k => v.id }
}

output "name_to_id" {
  description = "Map of peer names to peer IDs (for peers with name specified)"
  value       = { for k, v in netbird_peer.this : v.name => v.id if v.name != null }
}

output "peer_ips" {
  description = "Map of peer keys to assigned NetBird WireGuard IP addresses"
  value       = { for k, v in netbird_peer.this : k => v.ip }
}

output "peer_metadata" {
  description = "Comprehensive map of computed peer telemetry and network properties"
  value = {
    for k, v in netbird_peer.this : k => {
      id                            = v.id
      name                          = v.name
      ip                            = v.ip
      hostname                      = v.hostname
      dns_label                     = v.dns_label
      connected                     = v.connected
      connection_ip                 = v.connection_ip
      country_code                  = v.country_code
      city_name                     = v.city_name
      os                            = v.os
      version                       = v.version
      ui_version                    = v.ui_version
      kernel_version                = v.kernel_version
      groups                        = v.groups
      ssh_enabled                   = v.ssh_enabled
      approval_required             = v.approval_required
      login_expiration_enabled      = v.login_expiration_enabled
      login_expired                 = v.login_expired
      inactivity_expiration_enabled = v.inactivity_expiration_enabled
      last_login                    = v.last_login
      last_seen                     = v.last_seen
      user_id                       = v.user_id
    }
  }
}

output "peer_groups" {
  description = "Map of peer keys to their associated NetBird group IDs"
  value       = { for k, v in netbird_peer.this : k => v.groups }
}

