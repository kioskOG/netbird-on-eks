variable "items" {
  description = "Map of netbird_nameserver_group configuration objects"
  type = map(object({
    name   = string
    groups = list(string)
    nameservers = list(object({
      ip      = string
      ns_type = optional(string)
      port    = optional(number)
    }))
    description            = optional(string)
    domains                = optional(list(string))
    enabled                = optional(bool)
    primary                = optional(bool)
    search_domains_enabled = optional(bool)
  }))
  default = {}
}
