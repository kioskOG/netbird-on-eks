include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../..//infrastructure-modules/external-secrets"
}

dependency "iam_role" {
  config_path = "../../global/iam/role"
  mock_outputs = {
    iam_role_arns = {
      ESOControllerServiceAccountRole = "arn:aws:iam::123456789012:role/ESOControllerServiceAccountRole"
    }
  }
}

dependency "eks" {
  config_path = "../eks"
  mock_outputs = {
    eks_cluster_id = "mock-cluster"
  }
}

inputs = {
  release_namespace        = "external-secrets"
  chart_version            = "0.11.0"
  service_account_name     = "external-secrets"
  service_account_role_arn = dependency.iam_role.outputs.iam_role_arns["ESOControllerServiceAccountRole"]
}
