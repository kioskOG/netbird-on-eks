# Identity Provider Live Configuration (Pattern A: Dynamic Ingestion from AWS Secrets Manager)
# NOTE: Current Keycloak IdP on EKS is managed by Helm post-upgrade job.
# Do NOT run terragrunt apply or import without following the migration runbook in docs/netbird-terragrunt-architecture.md.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

# The Helm idp-sync job already owns the Keycloak IdP (type "keycloak", name from idp.name).
# The provider only accepts oidc-style types, so applying this adds a second IdP for the
# same Keycloak client instead of managing the existing one.
# Skipped by `terragrunt run --all` unless NB_ENABLE_IDP_TF=true.
exclude {
  if      = get_env("NB_ENABLE_IDP_TF", "false") != "true"
  actions = ["all"]
}

terraform {
  source = "../../../../../..//netbird-terraform/modules/identity-provider"
}

locals {
  # Load account vars for AWS region context
  account_vars = merge(yamldecode(file(find_in_parent_folders("account.yaml", "${get_terragrunt_dir()}/account.yaml"))), try(yamldecode(file(replace(find_in_parent_folders("account.yaml", "${get_terragrunt_dir()}/account.yaml"), "/\\.yaml$/", ".local.yaml"))), {}))
  aws_region   = local.account_vars.aws_region
  env_vars     = merge(yamldecode(file(find_in_parent_folders("env.yaml"))), try(yamldecode(file(replace(find_in_parent_folders("env.yaml"), "/\\.yaml$/", ".local.yaml"))), {}))

  # Dynamic Ingestion (Pattern A):
  # Ingests 'idp-client-secret' from AWS Secrets Manager secret 'dev/netbird/keys' at runtime in memory.
  # Without AWS credentials the secret resolves to "", which the module rejects at plan time,
  # so a placeholder can never be written to the IdP.
  secret_raw = try(
    run_cmd(
      "--terragrunt-quiet",
      "aws", "secretsmanager", "get-secret-value",
      "--secret-id", "dev/netbird/keys",
      "--region", local.aws_region,
      "--query", "SecretString",
      "--output", "text"
    ),
    "{}"
  )
  secret_data = jsondecode(local.secret_raw)
}

inputs = {
  name          = "Keycloak-SSO"
  type          = "oidc"
  issuer        = "https://keycloak.${local.env_vars.domain}/realms/netbird"
  client_id     = "netbird"
  client_secret = try(local.secret_data["idp-client-secret"], "")
}
