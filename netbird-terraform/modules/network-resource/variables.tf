variable "network_id" {
  description = "Default network ID for resources in this module (can be overridden per-item)"
  type        = string
  default     = null
}

variable "items" {
  description = "Map of netbird_network_resource configuration objects"
  type = map(object({
    address     = string
    groups      = set(string)
    name        = string
    network_id  = optional(string)
    description = optional(string)
    enabled     = optional(bool)
  }))
  default = {}
}
