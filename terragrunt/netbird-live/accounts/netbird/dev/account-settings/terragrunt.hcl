include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../..//netbird-terraform/modules/account-settings"
}

inputs = {
  peer_login_expiration_enabled      = true
  peer_login_expiration              = 86400
  peer_inactivity_expiration_enabled = false
  peer_inactivity_expiration         = 600
  peer_approval_enabled              = false
  user_approval_required             = false
  jwt_groups_enabled                 = false
  # jwt_groups_claim_name               = "groups"
  groups_propagation_enabled          = true
  network_traffic_logs_enabled        = false
  routing_peer_dns_resolution_enabled = true
}
