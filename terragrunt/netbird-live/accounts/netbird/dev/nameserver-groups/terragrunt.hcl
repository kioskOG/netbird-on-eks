include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../..//netbird-terraform/modules/nameserver-group"
}

locals {
  env_vars     = merge(yamldecode(file(find_in_parent_folders("env.yaml"))), try(yamldecode(file(replace(find_in_parent_folders("env.yaml"), "/\\.yaml$/", ".local.yaml"))), {}))
  account_vars = merge(yamldecode(file(find_in_parent_folders("account.yaml"))), try(yamldecode(file(replace(find_in_parent_folders("account.yaml"), "/\\.yaml$/", ".local.yaml"))), {}))
  env          = local.env_vars.env_name
  aws_region   = local.account_vars.aws_region
}

dependency "groups" {
  config_path = "../groups"
  mock_outputs = {
    group_ids = {
      devops_peers = "mock-group-devops-peers"
    }
  }
}

inputs = {
  items = {
    "aws_internal_dns" = {
      name        = "aws-vpc-resolver-${local.env}"
      description = "Forward internal domain queries to AWS VPC DNS"
      enabled     = true
      primary     = false
      # EC2 private DNS is ec2.internal only in us-east-1; other regions use
      # <region>.compute.internal. ${local.env}.netbird.internal is not forwarded:
      # NetBird serves it from the dns-zones unit, and the VPC resolver does not know it.
      domains = ["${local.aws_region}.compute.internal"]
      groups  = [dependency.groups.outputs.group_ids["devops_peers"]]
      nameservers = [
        {
          ip      = "10.36.0.2"
          ns_type = "udp"
          port    = 53
        }
      ]
    }
  }
}
