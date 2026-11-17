variable "items" {
  description = "Map of netbird_agent_network_provider configuration objects"
  type = map(object({
    name                    = string
    provider_id             = string
    upstream_url            = string
    api_key                 = string
    enabled                 = optional(bool)
    extra_values            = optional(map(string))
    identity_header_groups  = optional(string)
    identity_header_user_id = optional(string)
    metadata_disabled       = optional(bool)
    skip_tls_verification   = optional(bool)
    models = optional(list(object({
      id            = string
      input_per_1k  = number
      output_per_1k = number
    })))
  }))
  default = {}
}


