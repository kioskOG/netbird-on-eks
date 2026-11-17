# Peer governance configuration
# NOTE: Peers register dynamically into NetBird via setup-keys or user login.
# Terraform's netbird_peer resource governs existing registered peers by ID.
# Do not attempt to provision brand-new peers from scratch through Terraform.
# Destroy deletes the peer from NetBird (the device must re-register). To stop managing a
# peer without deleting it, run `terragrunt state rm` before removing its item.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../..//netbird-terraform/modules/peer"
}

locals {
  env_vars  = merge(yamldecode(file(find_in_parent_folders("env.yaml"))), try(yamldecode(file(replace(find_in_parent_folders("env.yaml"), "/\\.yaml$/", ".local.yaml"))), {}))
  peer_name = local.env_vars.devops_peer_name
}

inputs = {
  items = {
    # Example governing an existing registered DevOps bastion peer
    (local.peer_name) = {
      #id                            = "ch49k28d9s01hfa23k80" # ID of the pre-registered peer
      name        = local.peer_name
      ssh_enabled = true
      #lookup_ip                     = "100.64.0.5"
      approval_required             = false
      login_expiration_enabled      = false
      inactivity_expiration_enabled = false
    }
  }
}
