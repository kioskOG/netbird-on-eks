variable "items" {
  description = "Map of netbird_setup_key configuration objects"
  type = map(object({
    allow_extra_dns_labels = optional(bool)
    auto_groups            = optional(list(string))
    ephemeral              = optional(bool)
    expiry_seconds         = optional(number)
    name                   = string
    revoked                = optional(bool)
    type                   = optional(string)
    usage_limit            = optional(number)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.items : contains(["one-off", "reusable"], v.type)
      if v.type != null
    ])
    error_message = "Setup key type must be 'one-off' or 'reusable'."
  }
}

