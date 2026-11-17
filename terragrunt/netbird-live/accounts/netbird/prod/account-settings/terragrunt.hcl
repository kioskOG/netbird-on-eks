include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../..//netbird-terraform/modules/account-settings"
}

inputs = {
  peer_login_expiration_enabled       = true
  peer_login_expiration               = 43200 # 12 hours in production
  peer_inactivity_expiration_enabled  = true
  peer_inactivity_expiration          = 604800 # 7 days
  peer_approval_enabled               = true
  user_approval_required              = true
  jwt_groups_enabled                  = true
  jwt_groups_claim_name               = "groups"
  groups_propagation_enabled          = true
  network_traffic_logs_enabled        = true
  routing_peer_dns_resolution_enabled = true
}
