variable "items" {
  description = "Map of netbird_policy configuration objects"
  type = map(object({
    name                  = string
    description           = optional(string)
    enabled               = optional(bool)
    source_posture_checks = optional(list(string))
    rule = optional(list(object({
      name          = string
      action        = optional(string)
      bidirectional = optional(bool)
      description   = optional(string)
      enabled       = optional(bool)
      protocol      = optional(string)
      sources       = optional(list(string))
      source_resource = optional(object({
        id   = string
        type = string
      }))
      destinations = optional(list(string))
      destination_resource = optional(object({
        id   = string
        type = string
      }))
      ports = optional(list(string))
      port_ranges = optional(list(object({
        start = number
        end   = number
      })))
      authorized_groups = optional(map(list(string)))
    })))
  }))
  default = {}

  validation {
    condition = alltrue(flatten([
      for k, v in var.items : [
        for r in(v.rule != null ? v.rule : []) :
        contains(["accept", "drop"], r.action)
        if r.action != null
      ]
    ]))
    error_message = "Rule action must be 'accept' or 'drop'."
  }

  validation {
    condition = alltrue(flatten([
      for k, v in var.items : [
        for r in(v.rule != null ? v.rule : []) :
        contains(["tcp", "udp", "icmp", "all", "netbird-ssh"], r.protocol)
        if r.protocol != null
      ]
    ]))
    error_message = "Rule protocol must be one of: tcp, udp, icmp, all, netbird-ssh."
  }
}

