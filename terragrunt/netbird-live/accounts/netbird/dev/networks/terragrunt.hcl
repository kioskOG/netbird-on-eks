include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../..//netbird-terraform/modules/network"
}

locals {
  env_vars     = merge(yamldecode(file(find_in_parent_folders("env.yaml"))), try(yamldecode(file(replace(find_in_parent_folders("env.yaml"), "/\\.yaml$/", ".local.yaml"))), {}))
  account_vars = merge(yamldecode(file(find_in_parent_folders("account.yaml"))), try(yamldecode(file(replace(find_in_parent_folders("account.yaml"), "/\\.yaml$/", ".local.yaml"))), {}))

  env          = local.env_vars.env_name
  region_parts = split("-", local.account_vars.aws_region)
  region       = "${local.region_parts[0]}${substr(local.region_parts[1], 0, 1)}${local.region_parts[2]}" # us-east-2 -> use2
}

inputs = {
  items = {
    "aws_use2" = {
      name        = "net-aws-${local.region}-${local.env}"
      description = "AWS Virtual Network for NetBird mesh in ${local.region} (${local.env})"
    }
  }
}
