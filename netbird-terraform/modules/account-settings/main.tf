resource "netbird_account_settings" "this" {
  auto_update_version                    = var.auto_update_version
  dns_domain                             = var.dns_domain
  groups_propagation_enabled             = var.groups_propagation_enabled
  jwt_allow_groups                       = var.jwt_allow_groups
  jwt_groups_claim_name                  = var.jwt_groups_claim_name
  jwt_groups_enabled                     = var.jwt_groups_enabled
  lazy_connection_enabled                = var.lazy_connection_enabled
  network_range                          = var.network_range
  network_traffic_logs_enabled           = var.network_traffic_logs_enabled
  network_traffic_logs_groups            = var.network_traffic_logs_groups
  network_traffic_packet_counter_enabled = var.network_traffic_packet_counter_enabled
  peer_approval_enabled                  = var.peer_approval_enabled
  peer_expose_enabled                    = var.peer_expose_enabled
  peer_expose_groups                     = var.peer_expose_groups
  peer_inactivity_expiration             = var.peer_inactivity_expiration
  peer_inactivity_expiration_enabled     = var.peer_inactivity_expiration_enabled
  peer_login_expiration                  = var.peer_login_expiration
  peer_login_expiration_enabled          = var.peer_login_expiration_enabled
  regular_users_view_blocked             = var.regular_users_view_blocked
  routing_peer_dns_resolution_enabled    = var.routing_peer_dns_resolution_enabled
  user_approval_required                 = var.user_approval_required
}
