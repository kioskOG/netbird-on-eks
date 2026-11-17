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
  source = "../../../../../..//netbird-terraform/modules/agent-network-guardrail"
}

inputs = {
  items = {
    "strict_filter" = {
      name        = "guardrail-strict-dev"
      description = "Model allowlist and PII redaction"
      model_allowlist = {
        enabled = true
        models  = ["gpt-4o", "gpt-4o-mini"]
      }
      prompt_capture = {
        enabled    = false
        redact_pii = true
      }
    }
  }
}
