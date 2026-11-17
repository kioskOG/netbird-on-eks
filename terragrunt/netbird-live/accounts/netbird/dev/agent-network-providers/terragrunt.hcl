include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Agent Network runs on the NetBird proxy, which this deployment does not run yet.
# api_key below is a placeholder; supply the real key before enabling.
# Skipped by `terragrunt run --all` unless NB_ENABLE_AGENT_NETWORK=true.
exclude {
  if      = get_env("NB_ENABLE_AGENT_NETWORK", "false") != "true"
  actions = ["all"]
}

terraform {
  source = "../../../../../..//netbird-terraform/modules/agent-network-provider"
}

inputs = {
  items = {
    "openai_gateway" = {
      name         = "openai-upstream"
      provider_id  = "openai"
      upstream_url = "https://api.openai.com/v1"
      api_key      = "mock-api-key-for-static-validation"
      enabled      = true
      models = [
        {
          id            = "gpt-4o"
          input_per_1k  = 5
          output_per_1k = 15
        }
      ]
    }
  }
}
