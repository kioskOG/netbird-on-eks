variable "items" {
  description = "Map of netbird_reverse_proxy_service configuration objects"
  type = map(object({
    name              = string
    domain            = string
    enabled           = optional(bool)
    listen_port       = optional(number)
    mode              = optional(string)
    pass_host_header  = optional(bool)
    rewrite_redirects = optional(bool)
    access_restrictions = optional(object({
      allowed_cidrs     = optional(list(string))
      allowed_countries = optional(list(string))
      blocked_cidrs     = optional(list(string))
      blocked_countries = optional(list(string))
    }))
    auth = object({
      bearer_auth = optional(object({
        enabled             = bool
        distribution_groups = optional(list(string))
      }))
      header_auths = optional(list(object({
        enabled = bool
        header  = string
        value   = string
      })))
      link_auth = optional(object({
        enabled = bool
      }))
      password_auth = optional(object({
        enabled  = bool
        password = optional(string)
      }))
      pin_auth = optional(object({
        enabled = bool
        pin     = optional(string)
      }))
    })
    targets = list(object({
      target_id   = string
      target_type = string
      protocol    = string
      port        = number
      path        = optional(string)
      enabled     = optional(bool)
      host        = optional(string)
      options = optional(object({
        custom_headers       = optional(map(string))
        path_rewrite         = optional(string)
        proxy_protocol       = optional(bool)
        request_timeout      = optional(string)
        session_idle_timeout = optional(string)
        skip_tls_verify      = optional(bool)
      }))
    }))
  }))
  default = {}



  validation {
    condition = alltrue([
      for k, v in var.items : contains(["http", "tcp", "udp", "tls"], v.mode)
      if v.mode != null
    ])
    error_message = "Reverse proxy service mode must be one of: http, tcp, udp, tls."
  }
}

