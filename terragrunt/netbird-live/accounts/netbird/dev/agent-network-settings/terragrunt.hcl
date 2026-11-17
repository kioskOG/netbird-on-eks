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
  source = "../../../../../..//netbird-terraform/modules/agent-network-settings"
}

inputs = {
  access_log_retention_days = 30
  enable_log_collection     = true
  enable_prompt_collection  = false
  redact_pii                = true
}
