include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../..//infrastructure-modules/vpc/"
}

locals {
  common_vars  = merge(yamldecode(file("${get_terragrunt_dir()}/../common.yaml")), try(yamldecode(file(replace("${get_terragrunt_dir()}/../common.yaml", "/\\.yaml$/", ".local.yaml"))), {}))
  cluster_name = "netbird"
}

inputs = {
  region               = local.common_vars["aws_region"]
  cidr_block           = "10.36.0.0/16"
  vpc_name             = "netbird"
  vpc_env              = local.common_vars["env_name"] #"dev"
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_cidr_block        = ["10.36.0.0/20", "10.36.16.0/20", "10.36.32.0/20"]
  public_subnet_availability_zone = [for az in ["a", "b", "c"] : "${local.common_vars.aws_region}${az}"]
  map_public_ip_on_launch         = true

  db_subnet_cidr_block        = ["10.36.48.0/20", "10.36.64.0/20", "10.36.80.0/20"]
  availability_zone_db_subnet = [for az in ["a", "b", "c"] : "${local.common_vars.aws_region}${az}"]

  private_subnet_cidr_block        = ["10.36.96.0/19", "10.36.128.0/19", "10.36.160.0/19"]
  availability_zone_private_subnet = [for az in ["a", "b", "c"] : "${local.common_vars.aws_region}${az}"]

  sg_ingress_rules = []
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"             = 1
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }
  public_subnet_tags = {
    "kubernetes.io/role/elb"                      = 1
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }
}

# https://www.davidc.net/sites/default/subnets/subnets.html