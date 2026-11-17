include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../..//infrastructure-modules/iam/"
}

dependency "eks" {
  config_path = "../../../us-east-2/eks"
  mock_outputs = {
    oidc_issuer_url   = "https://oidc.eks.us-east-2.amazonaws.com/id/MOCK"
    oidc_provider_arn = "arn:aws:iam::<AWS_ACCOUNT_ID>:oidc-provider/oidc.eks.us-east-2.amazonaws.com/id/MOCK"
  }
}

locals {
  common_vars = merge(yamldecode(file("${get_terragrunt_dir()}/../../../us-east-2/common.yaml")), try(yamldecode(file(replace("${get_terragrunt_dir()}/../../../us-east-2/common.yaml", "/\\.yaml$/", ".local.yaml"))), {}))
}

inputs = {

  policy_vars       = local.common_vars
  oidc_issuer_url   = dependency.eks.outputs.oidc_issuer_url
  oidc_provider_arn = dependency.eks.outputs.oidc_provider_arn

  iam_role = {

    ESOControllerServiceAccountRole = {
      irsa_service_accounts = ["external-secrets:external-secrets"]
      custom_policy = [
        "ESOSecretsManagerAccessPolicy"
      ]
      managed_policy = []
    }

    AWSLoadBalancerControllerRole = {
      irsa_service_accounts = ["kube-system:aws-load-balancer-controller"]
      custom_policy = [
        "AWSLoadBalancerController"
      ]
      managed_policy = []
    }
  }
}

