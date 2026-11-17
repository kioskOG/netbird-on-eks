variable "items" {
  description = "Map of netbird_agent_network_guardrail configuration objects"
  type = map(object({
    name        = string
    description = optional(string)
    model_allowlist = object({
      models  = list(string)
      enabled = optional(bool)
    })
    prompt_capture = object({
      enabled    = optional(bool)
      redact_pii = optional(bool)
    })
  }))
  default = {}
}
