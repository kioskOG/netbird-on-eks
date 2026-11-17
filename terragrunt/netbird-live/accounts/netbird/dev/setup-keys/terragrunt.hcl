include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../..//netbird-terraform/modules/setup-key"
}

locals {
  env_vars = merge(yamldecode(file(find_in_parent_folders("env.yaml"))), try(yamldecode(file(replace(find_in_parent_folders("env.yaml"), "/\\.yaml$/", ".local.yaml"))), {}))
  env      = local.env_vars.env_name
}

dependency "groups" {
  config_path = "../groups"
  mock_outputs = {
    group_ids = {
      orders_web    = "mock-group-orders-web"
      orders_db     = "mock-group-orders-db"
      devops_peers  = "mock-group-devops-peers"
      support_peers = "mock-group-support-peers"
    }
  }
}

inputs = {
  items = {
    "k8s_nodes" = {
      name           = "setup-${local.env}-k8s-nodes"
      type           = "reusable"
      expiry_seconds = 2592000 # 30 days
      auto_groups    = [dependency.groups.outputs.group_ids["orders_web"]]
      usage_limit    = 0 # unlimited peers
      ephemeral      = false
    }
    "bastion" = {
      name           = "setup-${local.env}-bastion"
      type           = "reusable"
      expiry_seconds = 604800 # 7 days
      auto_groups    = [dependency.groups.outputs.group_ids["devops_peers"]]
      usage_limit    = 5 # five peers
      ephemeral      = true
    }
  }
}
