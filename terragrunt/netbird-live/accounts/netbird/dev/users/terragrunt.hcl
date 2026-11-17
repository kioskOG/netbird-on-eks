include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../..//netbird-terraform/modules/user"
}

locals {
  env_vars = merge(yamldecode(file(find_in_parent_folders("env.yaml"))), try(yamldecode(file(replace(find_in_parent_folders("env.yaml"), "/\\.yaml$/", ".local.yaml"))), {}))
}

dependency "groups" {
  config_path = "../groups"
  mock_outputs = {
    group_ids = {
      devops_peers = "mock-group-devops-peers"
    }
  }
}

inputs = {
  items = {
    "cicd_bot" = {
      name            = "cicd-service-bot"
      is_service_user = true
      role            = "network_admin"
      auto_groups     = [dependency.groups.outputs.group_ids["devops_peers"]]
    }
    "lead_admin" = {
      name            = "devops-admin"
      email           = "admin@${local.env_vars.domain}"
      is_service_user = false
      role            = "admin"
    }
  }
}
