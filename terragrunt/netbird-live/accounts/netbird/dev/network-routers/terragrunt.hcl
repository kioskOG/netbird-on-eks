include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../..//netbird-terraform/modules/network-router"
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
      orders_web   = "mock-group-orders-web"
      devops_peers = "mock-group-devops-peers"
    }
  }
}

inputs = {
  # Optional: module-level default network_id fallback when omitted on individual items
  # network_id = dependency.networks.outputs.network_ids["aws_use2"]

  items = {
    # ---------------------------------------------------------------------------------------------
    # Option A: Routing via Peer Group (High Availability Routing Peers)
    # Any peer assigned to the group will route traffic into the network's resources.
    # ---------------------------------------------------------------------------------------------
    "group_ha_router" = {
      network_id  = dependency.networks.outputs.network_ids["aws_use2"]
      peer_groups = [dependency.groups.outputs.group_ids["orders_web"]]
      masquerade  = true
      metric      = 9999
      enabled     = true
    }

    # Option B: a single routing peer instead of a group. 'peer' and 'peer_groups' are mutually
    # exclusive. Routers on one network act as HA peers and clients can pick any of them, so
    # every router must reach the network's resources (10.36.0.0/16). A laptop cannot.
    #   peer = "<peer id of an in-VPC gateway>"
  }
}
