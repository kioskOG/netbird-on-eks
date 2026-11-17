variable "items" {
  description = "Map of netbird_user configuration objects"
  type = map(object({
    auto_groups     = optional(list(string))
    email           = optional(string)
    is_blocked      = optional(bool)
    is_service_user = bool
    name            = optional(string)
    role            = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.items : contains(["owner", "admin", "user", "billing_admin", "auditor", "network_admin"], v.role)
      if v.role != null
    ])
    error_message = "User role must be one of: owner, admin, user, billing_admin, auditor, network_admin."
  }
}

