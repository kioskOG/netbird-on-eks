include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../..//netbird-terraform/modules/network-resource"
}

dependency "networks" {
  config_path = "../networks"
  mock_outputs = {
    network_ids = {
      aws_use2 = "mock-network-aws-use2"
    }
  }
}

dependency "groups" {
  config_path = "../groups"
  mock_outputs = {
    group_ids = {
      orders_db    = "mock-group-orders-db"
      devops_peers = "mock-group-devops-peers"
    }
  }
}

inputs = {
  # Optional: module-level default network_id fallback when omitted on individual items
  # network_id = dependency.networks.outputs.network_ids["aws_use2"]

  items = {
    "db_endpoint" = {
      name        = "svc-orders-db-dev"
      network_id  = dependency.networks.outputs.network_ids["aws_use2"]
      address     = "10.36.48.15/32"
      description = "Orders Database Private Subnet IP"
      enabled     = true
      groups      = [dependency.groups.outputs.group_ids["orders_db"]]
    }
  }

}

