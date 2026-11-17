variable "network_id" {
  description = "Default network ID for routers in this module (can be overridden per-item)"
  type        = string
  default     = null
}

variable "items" {
  description = "Map of netbird_network_router configuration objects"
  type = map(object({
    network_id  = optional(string)
    enabled     = optional(bool)
    masquerade  = optional(bool)
    metric      = optional(number)
    peer        = optional(string)
    peer_groups = optional(list(string))
  }))
  default = {}
}
