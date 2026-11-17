include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../..//netbird-terraform/modules/route"
}

locals {
  env_vars     = merge(yamldecode(file(find_in_parent_folders("env.yaml"))), try(yamldecode(file(replace(find_in_parent_folders("env.yaml"), "/\\.yaml$/", ".local.yaml"))), {}))
  account_vars = merge(yamldecode(file(find_in_parent_folders("account.yaml"))), try(yamldecode(file(replace(find_in_parent_folders("account.yaml"), "/\\.yaml$/", ".local.yaml"))), {}))
  env          = local.env_vars.env_name
  region_parts = split("-", local.account_vars.aws_region)
  region       = "${local.region_parts[0]}${substr(local.region_parts[1], 0, 1)}${local.region_parts[2]}" # us-east-2 -> use2
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
  # Legacy Network Routes (dashboard: Network Routes). network_id is the route's
  # "Network Identifier": a free-form label (max 40 chars) that groups HA routes for
  # the same range. It is not a netbird_network ID; Networks are configured in the
  # networks / network-resources / network-routers units.
  network_id = "aws-${local.region}-vpc-${local.env}"

  items = {
    "vpc_subnet_route" = {
      network     = "10.36.0.0/16"
      description = "AWS VPC CIDR Access Route"
      enabled     = true
      masquerade  = true
      metric      = 9999
      groups      = [dependency.groups.outputs.group_ids["devops_peers"]]
      peer_groups = [dependency.groups.outputs.group_ids["orders_web"]]
    }
  }
}
