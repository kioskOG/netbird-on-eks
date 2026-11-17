include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../..//infrastructure-modules/postgresql"
}

dependency "eks" {
  config_path = "../eks"
  mock_outputs = {
    eks_cluster_id = "mock-cluster-id"
  }
}

dependency "external_secrets" {
  config_path = "../external-secrets"
  mock_outputs = {
    cluster_secret_store_name = "mock-aws-secretsmanager"
  }
}

inputs = {
  aws_secret_name           = "dev/netbird/postgresql"
  cluster_secret_store_name = dependency.external_secrets.outputs.cluster_secret_store_name

  cnpg_chart_version = "0.29.1"
  namespace          = "netbird"
  cnpg_namespace     = "cnpg-system"
  cluster_name       = "netbird-postgresql"

  instances      = 1
  storage_size   = "20Gi"
  storage_class  = "gp2"
  database_name  = "netbird"
  database_owner = "netbird"
}
