include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Needs a NetBird proxy cluster; this deployment does not run one yet. targets[].target_id
# below is a placeholder and must be a real peer or resource ID.
# Skipped by `terragrunt run --all` unless NB_ENABLE_REVERSE_PROXY=true.
exclude {
  if      = get_env("NB_ENABLE_REVERSE_PROXY", "false") != "true"
  actions = ["all"]
}

terraform {
  source = "../../../../../..//netbird-terraform/modules/reverse-proxy-service"
}

locals {
  env_vars = merge(yamldecode(file(find_in_parent_folders("env.yaml"))), try(yamldecode(file(replace(find_in_parent_folders("env.yaml"), "/\\.yaml$/", ".local.yaml"))), {}))
  env      = local.env_vars.env_name
}

dependency "proxy_domains" {
  config_path = "../reverse-proxy-domains"
  mock_outputs = {
    domain_to_id = {
      "proxy-${local.env}.${local.env_vars.domain}" = "mock-proxy-domain-id"
    }
  }
}

inputs = {
  items = {
    "orders_api_ingress" = {
      name              = "svc-orders-ingress-${local.env}"
      domain            = "proxy-${local.env}.${local.env_vars.domain}"
      enabled           = true
      mode              = "http"
      pass_host_header  = true
      rewrite_redirects = true
      auth = {
        bearer_auth = {
          enabled = true
        }
      }
      targets = [
        {
          target_id   = "target-peer-01"
          target_type = "peer"
          protocol    = "http"
          port        = 8080
          path        = "/api/v1"
        }
      ]
    }
  }
}
