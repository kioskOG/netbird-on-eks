variable "items" {
  description = "Map of netbird_network configuration objects"
  type = map(object({
    description = optional(string)
    name        = string
  }))
  default = {}
}
