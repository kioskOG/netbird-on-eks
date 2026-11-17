variable "items" {
  description = "Map of netbird_agent_network_policy configuration objects"
  type = map(object({
    name                     = string
    destination_provider_ids = list(string)
    source_groups            = list(string)
    description              = optional(string)
    enabled                  = optional(bool)
    guardrail_ids            = optional(list(string))
    budget_limit = optional(object({
      enabled        = optional(bool)
      group_cap_usd  = optional(number)
      user_cap_usd   = optional(number)
      window_seconds = optional(number)
    }))
    token_limit = optional(object({
      enabled        = optional(bool)
      group_cap      = optional(number)
      user_cap       = optional(number)
      window_seconds = optional(number)
    }))
  }))
  default = {}
}
