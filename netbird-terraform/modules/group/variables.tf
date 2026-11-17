variable "items" {
  description = "Map of netbird_group configuration objects"
  type = map(object({
    name      = string
    peers     = optional(list(string))
    resources = optional(list(string))
  }))
  default = {}
}
