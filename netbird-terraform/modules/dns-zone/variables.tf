variable "items" {
  description = "Map of netbird_dns_zone configuration objects"
  type = map(object({
    distribution_groups  = optional(set(string))
    domain               = string
    enable_search_domain = optional(bool)
    enabled              = optional(bool)
    name                 = string
  }))
  default = {}
}
