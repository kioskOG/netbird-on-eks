include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../..//infrastructure-modules/iam/"
}

locals {
  common_vars  = merge(yamldecode(file("${get_terragrunt_dir()}/../common.yaml")), try(yamldecode(file(replace("${get_terragrunt_dir()}/../common.yaml", "/\\.yaml$/", ".local.yaml"))), {}))
  cluster_name = "netbird"
}

dependency "eks" {
  config_path = "../us-east-2/eks"
  mock_outputs = {
    oidc_issuer_url   = "https://oidc.eks.us-east-2.amazonaws.com/id/MOCK"
    oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-2.amazonaws.com/id/MOCK"
  }
}

inputs = {
  region            = local.common_vars["aws_region"]
  oidc_issuer_url   = dependency.eks.outputs.oidc_issuer_url
  oidc_provider_arn = dependency.eks.outputs.oidc_provider_arn

  # Roles configuration relying on local policies that would be generated or placed in infrastructure-modules/iam/policy
  # NOTE: the existing IAM module expects policy files to exist in `trusted-entity/` or `policy/` relative to the module
  # For IRSA, we just define irsa_service_accounts
  iam_role = {
    "netbird-aws-load-balancer-controller" = {
      irsa_service_accounts = ["kube-system:aws-load-balancer-controller"]
      custom_policy         = ["AWSLoadBalancerControllerIAMPolicy"]
    }

  }
}
