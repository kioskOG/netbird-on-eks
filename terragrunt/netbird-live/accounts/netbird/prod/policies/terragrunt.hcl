include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../..//netbird-terraform/modules/policy"
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

inputs = {
  items = {
    "devops_to_web" = {
      name        = "peer-devops-prod -> svc-orders-web-prod [TCP/443]"
      description = "Allow DevOps engineers HTTPS access to Orders Web tier (Prod)"
      enabled     = true
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
  }
}
