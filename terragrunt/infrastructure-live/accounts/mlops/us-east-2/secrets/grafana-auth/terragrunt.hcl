include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../..//infrastructure-modules/secrets"
}

locals {
  common_vars = merge(yamldecode(file("${get_terragrunt_dir()}/../../common.yaml")), try(yamldecode(file(replace("${get_terragrunt_dir()}/../../common.yaml", "/\\.yaml$/", ".local.yaml"))), {}))
}

dependency "grafana_keycloak" {
  config_path = "../../keycloak/grafana"

  mock_outputs = {
    client_secret = "mock-secret-for-plan"
    client = {
      client_id = "mock-client-id"
    }
  }
}

inputs = {
  region = local.common_vars.aws_region
  secrets = {
    "observability-hub/grafana-auth" = {
      description = "Grafana OIDC Client Secret (Published by Terraform)"
      values = {
        GRAFANA_OAUTH_CLIENT_SECRET = dependency.grafana_keycloak.outputs.client_secret
      }
    }
  }
}
