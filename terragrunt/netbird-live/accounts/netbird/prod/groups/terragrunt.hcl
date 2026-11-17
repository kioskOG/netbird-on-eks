include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../..//netbird-terraform/modules/group"
}

locals {
  env_vars = merge(yamldecode(file(find_in_parent_folders("env.yaml"))), try(yamldecode(file(replace(find_in_parent_folders("env.yaml"), "/\\.yaml$/", ".local.yaml"))), {}))
  env      = local.env_vars.env_name
}

inputs = {
  items = {
    "orders_web" = {
      name = "svc-orders-web-${local.env}"
    }
    "orders_db" = {
      name = "svc-orders-db-${local.env}"
    }
    "devops_peers" = {
      name = "peer-devops-${local.env}"
    }
    "support_peers" = {
      name = "peer-support-${local.env}"
    }
  }
}
