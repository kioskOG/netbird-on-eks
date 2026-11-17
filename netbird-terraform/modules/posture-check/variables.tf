variable "items" {
  description = "Map of netbird_posture_check configuration objects"
  type = map(object({
    name        = string
    description = optional(string)
    geo_location_check = optional(object({
      action = optional(string)
      locations = optional(list(object({
        country_code = string
        city_name    = optional(string)
      })))
    }))
    netbird_version_check = optional(object({
      min_version = optional(string)
    }))
    os_version_check = optional(object({
      android_min_version        = optional(string)
      darwin_min_version         = optional(string)
      ios_min_version            = optional(string)
      linux_min_kernel_version   = optional(string)
      windows_min_kernel_version = optional(string)
    }))
    peer_network_range_check = optional(object({
      action = optional(string)
      ranges = optional(list(string))
    }))
    process_check = optional(list(object({
      linux_path   = optional(string)
      mac_path     = optional(string)
      windows_path = optional(string)
    })))
  }))
  default = {}
}
