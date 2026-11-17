include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Needs a NetBird proxy cluster; this deployment does not run one yet. target_cluster must
# be a cluster address from data.netbird_reverse_proxy_clusters, not a placeholder.
# Skipped by `terragrunt run --all` unless NB_ENABLE_REVERSE_PROXY=true.
exclude {
  if      = get_env("NB_ENABLE_REVERSE_PROXY", "false") != "true"
  actions = ["all"]
}

terraform {
  source = "../../../../../..//netbird-terraform/modules/reverse-proxy-domain"
}

locals {
  env_vars = merge(yamldecode(file(find_in_parent_folders("env.yaml"))), try(yamldecode(file(replace(find_in_parent_folders("env.yaml"), "/\\.yaml$/", ".local.yaml"))), {}))
  env      = local.env_vars.env_name
}

inputs = {
  items = {
    "main_domain" = {
      domain         = "proxy-${local.env}.${local.env_vars.domain}"
      target_cluster = "default"
    }
  }
}
