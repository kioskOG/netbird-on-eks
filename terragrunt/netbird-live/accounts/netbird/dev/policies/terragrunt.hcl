include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../..//netbird-terraform/modules/policy"
}

locals {
  env_vars  = merge(yamldecode(file(find_in_parent_folders("env.yaml"))), try(yamldecode(file(replace(find_in_parent_folders("env.yaml"), "/\\.yaml$/", ".local.yaml"))), {}))
  peer_name = local.env_vars.devops_peer_name
}

dependency "groups" {
  config_path = "../groups"
  mock_outputs = {
    group_ids = {
      orders_web   = "mock-group-orders-web"
      orders_db    = "mock-group-orders-db"
      devops_peers = "mock-group-devops-peers"
    }
  }
}

dependency "posture_checks" {
  config_path = "../posture-checks"
  mock_outputs = {
    posture_check_ids = {
      compliance_baseline = "mock-posture-check-id"
    }
  }
}

dependency "peers" {
  config_path = "../peers"
  mock_outputs = {
    peer_ids = {
      (local.peer_name) = "mock-peer-id-macbook"
    }
    peer_groups = {
      (local.peer_name) = ["mock-group-devops-peers"]
    }
  }
}

dependency "network_resources" {
  config_path = "../network-resources"
  mock_outputs = {
    network_resource_ids = {
      db_endpoint = "mock-resource-id-db"
    }
  }
}

inputs = {
  items = {
    # ---------------------------------------------------------------------------------------------
    # Pattern 1: Group-to-Group Traffic Policy
    # ---------------------------------------------------------------------------------------------
    "devops_to_web" = {
      name                  = "peer-devops-dev -> svc-orders-web-dev [TCP/443]"
      description           = "Allow DevOps group HTTPS access to Orders Web tier"
      enabled               = true
      source_posture_checks = [dependency.posture_checks.outputs.posture_check_ids["compliance_baseline"]]
      rule = [
        {
          name          = "allow-https"
          action        = "accept"
          protocol      = "tcp"
          bidirectional = false
          sources       = [dependency.groups.outputs.group_ids["devops_peers"]]
          destinations  = [dependency.groups.outputs.group_ids["orders_web"]]
          ports         = ["443"]
        }
      ]
    }

    # ---------------------------------------------------------------------------------------------
    # Pattern 2: Peer-to-Group / Group-to-Peer Access Policy
    # Note: target a single peer with source_resource (type "peer"), the same as picking a peer
    # as the source in the dashboard. Do not use the peer's groups: every peer is in the
    # built-in "All" group, so the rule would apply to all peers.
    # ---------------------------------------------------------------------------------------------
    "peer_to_group_access" = {
      name        = "macbook peer -> orders_web group [SSH & Web]"
      description = "Developer workstation peer access to Orders Web tier"
      enabled     = true
      rule = [
        {
          name          = "allow-peer-to-group"
          action        = "accept"
          protocol      = "all"
          bidirectional = true
          source_resource = {
            id   = dependency.peers.outputs.peer_ids[local.peer_name]
            type = "peer"
          }
          destinations = [dependency.groups.outputs.group_ids["orders_web"]]
        }
      ]
    }

    # ---------------------------------------------------------------------------------------------
    # Pattern 3: Group to Destination Network Resource Policy
    # Note: 'destination_resource' is mutually exclusive with 'destinations'.
    # type must match the network resource: 'host' (single IP), 'subnet' (CIDR) or 'domain'.
    # ---------------------------------------------------------------------------------------------
    "group_to_network_resource" = {
      name        = "svc-orders-web-dev -> db_endpoint resource [TCP/5432]"
      description = "Allow Orders Web tier access to private AWS RDS Database Network Resource"
      enabled     = true
      rule = [
        {
          name          = "allow-postgres-resource"
          action        = "accept"
          protocol      = "tcp"
          bidirectional = false
          sources       = [dependency.groups.outputs.group_ids["orders_web"]]
          destination_resource = {
            id   = dependency.network_resources.outputs.network_resource_ids["db_endpoint"]
            type = "host"
          }
          ports = ["5432"]
        }
      ]
    }

    # ---------------------------------------------------------------------------------------------
    # Pattern 4: Peer to Destination Network Resource Policy
    # Governs direct developer workstation peer access to an internal infrastructure resource.
    # ---------------------------------------------------------------------------------------------
    "peer_to_network_resource" = {
      name        = "macbook peer -> db_endpoint resource [TCP/5432]"
      description = "Allow Developer workstation peer direct access to RDS Database Network Resource"
      enabled     = true
      rule = [
        {
          name          = "allow-peer-to-db-resource"
          action        = "accept"
          protocol      = "tcp"
          bidirectional = false
          source_resource = {
            id   = dependency.peers.outputs.peer_ids[local.peer_name]
            type = "peer"
          }
          destination_resource = {
            id   = dependency.network_resources.outputs.network_resource_ids["db_endpoint"]
            type = "host"
          }
          ports = ["5432"]
        }
      ]
    }
  }
}
