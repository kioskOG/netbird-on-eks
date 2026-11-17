variable "network_id" {
  description = "Default network ID for routes in this module (can be overridden per-item)"
  type        = string
  default     = null
}

variable "items" {
  description = "Map of netbird_route configuration objects"
  type = map(object({
    groups                = list(string)
    network_id            = optional(string)
    access_control_groups = optional(list(string))
    description           = optional(string)
    domains               = optional(list(string))
    enabled               = optional(bool)
    keep_route            = optional(bool)
    masquerade            = optional(bool)
    metric                = optional(number)
    network               = optional(string)
    peer                  = optional(string)
    peer_groups           = optional(list(string))
    skip_auto_apply       = optional(bool)
  }))
  default = {}
}
