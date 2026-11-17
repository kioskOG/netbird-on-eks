include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../..//netbird-terraform/modules/dns-zone"
}

locals {
  env_vars = merge(yamldecode(file(find_in_parent_folders("env.yaml"))), try(yamldecode(file(replace(find_in_parent_folders("env.yaml"), "/\\.yaml$/", ".local.yaml"))), {}))
  env      = local.env_vars.env_name
}

dependency "groups" {
  config_path = "../groups"
  mock_outputs = {
    group_ids = {
      orders_web   = "mock-group-orders-web"
      devops_peers = "mock-group-devops-peers"
    }
  }
}

inputs = {
  items = {
    "internal_mesh" = {
      name                 = "mesh-${local.env}"
      domain               = "${local.env}.netbird.internal"
      enabled              = true
      enable_search_domain = true
      distribution_groups  = [dependency.groups.outputs.group_ids["devops_peers"]]
    }
  }
}
