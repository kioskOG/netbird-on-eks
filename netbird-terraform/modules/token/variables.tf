variable "items" {
  description = "Map of netbird_token configuration objects"
  type = map(object({
    expiration_days = number
    name            = string
    user_id         = string
  }))
  default = {}
}
