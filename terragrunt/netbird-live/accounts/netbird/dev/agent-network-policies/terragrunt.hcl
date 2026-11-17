include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Agent Network runs on the NetBird proxy, which this deployment does not run yet.
# Skipped by `terragrunt run --all` unless NB_ENABLE_AGENT_NETWORK=true.
exclude {
  if      = get_env("NB_ENABLE_AGENT_NETWORK", "false") != "true"
  actions = ["all"]
}

terraform {
  source = "../../../../../..//netbird-terraform/modules/agent-network-policy"
}

dependency "providers" {
  config_path = "../agent-network-providers"
  mock_outputs = {
    agent_network_provider_ids = {
      openai_gateway = "mock-provider-id"
    }
  }
}

dependency "guardrails" {
  config_path = "../agent-network-guardrails"
  mock_outputs = {
    agent_network_guardrail_ids = {
      strict_filter = "mock-guardrail-id"
    }
  }
}

dependency "groups" {
  config_path = "../groups"
  mock_outputs = {
    group_ids = {
      devops_peers = "mock-group-devops-peers"
    }
  }
}

inputs = {
  items = {
    "devops_ai_access" = {
      name                     = "policy-devops-ai-dev"
      destination_provider_ids = [dependency.providers.outputs.agent_network_provider_ids["openai_gateway"]]
      source_groups            = [dependency.groups.outputs.group_ids["devops_peers"]]
      guardrail_ids            = [dependency.guardrails.outputs.agent_network_guardrail_ids["strict_filter"]]
      enabled                  = true
      budget_limit = {
        enabled        = true
        group_cap_usd  = 100
        user_cap_usd   = 25
        window_seconds = 2592000
      }
    }
  }
}
