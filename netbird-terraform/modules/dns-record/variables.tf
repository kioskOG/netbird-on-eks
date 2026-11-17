variable "zone_id" {
  description = "Default DNS zone ID for records in this module (can be overridden per-item)"
  type        = string
  default     = null
}

variable "items" {
  description = "Map of netbird_dns_record configuration objects"
  type = map(object({
    content = string
    name    = string
    ttl     = optional(number)
    type    = string
    zone_id = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.items : contains(["A", "AAAA", "CNAME"], v.type)
    ])
    error_message = "DNS record type must be one of: A, AAAA, CNAME."
  }

  validation {
    condition = alltrue([
      for k, v in var.items : v.zone_id != null || var.zone_id != null
    ])
    error_message = "Each DNS record must specify zone_id or a module-level zone_id must be provided."
  }
}

