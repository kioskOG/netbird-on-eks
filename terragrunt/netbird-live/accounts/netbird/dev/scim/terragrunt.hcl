include "root" {
  path = find_in_parent_folders("root.hcl")
}

# SCIM is a NetBird Cloud integration. The self-hosted v0.80 management server has no
# SCIM API, so apply fails against a self-hosted server.
# Skipped by `terragrunt run --all` unless NB_ENABLE_SCIM=true.
exclude {
  if      = get_env("NB_ENABLE_SCIM", "false") != "true"
  actions = ["all"]
}

terraform {
  source = "../../../../../..//netbird-terraform/modules/scim"
}

inputs = {
  provider_name       = "keycloak-scim"
  enabled             = true
  prefix              = "nb-"
  group_prefixes      = ["svc-", "peer-"]
  user_group_prefixes = ["devops-", "engineering-"]
}
