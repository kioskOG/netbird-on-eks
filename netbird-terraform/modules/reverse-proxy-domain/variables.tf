variable "items" {
  description = "Map of netbird_reverse_proxy_domain configuration objects"
  type = map(object({
    domain         = string
    target_cluster = string
  }))
  default = {}
}
