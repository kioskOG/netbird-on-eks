variable "items" {
  description = "Map of netbird_peer configuration objects. If 'id' is omitted, the peer is looked up dynamically via data source using 'name' or 'lookup_ip'."
  type = map(object({
    id                            = optional(string)
    name                          = optional(string)
    lookup_name                   = optional(string)
    lookup_ip                     = optional(string)
    approval_required             = optional(bool)
    inactivity_expiration_enabled = optional(bool)
    login_expiration_enabled      = optional(bool)
    ssh_enabled                   = optional(bool)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.items : (
        v.id != null || v.name != null || v.lookup_name != null || v.lookup_ip != null
      )
    ])
    error_message = "Each peer item must specify either 'id', 'name', 'lookup_name', or 'lookup_ip' to identify the peer."
  }
}
