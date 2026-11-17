include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../..//infrastructure-modules/security-groups/"
}

locals {
  common_vars = merge(yamldecode(file("${get_terragrunt_dir()}/../common.yaml")), try(yamldecode(file(replace("${get_terragrunt_dir()}/../common.yaml", "/\\.yaml$/", ".local.yaml"))), {}))
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id = "vpc-mock1234567890"
  }
}

inputs = {
  vpc_id         = dependency.vpc.outputs.vpc_id
  sg_name        = "netbird-shared-sg"
  vpc_env        = local.common_vars["env_name"]
  sg_description = "Security group for NetBird shared resources"

  # Base SG rules - keeping it minimal, specific rules added by EKS module or later via NetBird config
  sg_ingress_rules = []
}
