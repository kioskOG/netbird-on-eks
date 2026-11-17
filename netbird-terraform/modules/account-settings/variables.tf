variable "auto_update_version" {
  description = "Set Clients auto-update version. \"latest\", \"disabled\", or a specific version (e.g. \"0.64.5\")"
  type        = string
  default     = null
}

variable "dns_domain" {
  description = "Allows to define a custom DNS domain for the account"
  type        = string
  default     = null
}

variable "groups_propagation_enabled" {
  description = "Allows propagate the new user auto groups to peers that belongs to the user"
  type        = bool
  default     = null
}

variable "jwt_allow_groups" {
  description = "List of groups to which users are allowed access"
  type        = list(string)
  default     = null
}

variable "jwt_groups_claim_name" {
  description = "Name of the claim from which we extract groups names to add it to account groups"
  type        = string
  default     = null
}

variable "jwt_groups_enabled" {
  description = "Allows extract groups from JWT claim and add it to account groups"
  type        = bool
  default     = null
}

variable "lazy_connection_enabled" {
  description = "Enables or disables experimental lazy connection"
  type        = bool
  default     = null
}

variable "network_range" {
  description = "Allows to define a custom network range for the account in CIDR format"
  type        = string
  default     = null
}

variable "network_traffic_logs_enabled" {
  description = "Enables or disables network traffic logging"
  type        = bool
  default     = null
}

variable "network_traffic_logs_groups" {
  description = "Limits traffic logging to these groups. If unset all peers are enabled"
  type        = list(string)
  default     = null
}

variable "network_traffic_packet_counter_enabled" {
  description = "Enables or disables network traffic packet counter"
  type        = bool
  default     = null
}

variable "peer_approval_enabled" {
  description = "(Cloud only) Enables or disables peer approval globally"
  type        = bool
  default     = null
}

variable "peer_expose_enabled" {
  description = "Enables or disables peer expose through reverse proxy using CLI"
  type        = bool
  default     = null
}

variable "peer_expose_groups" {
  description = "Limits which peer groups are allowed to expose services"
  type        = list(string)
  default     = null
}

variable "peer_inactivity_expiration" {
  description = "Period of time of inactivity after which peer session expires (seconds)"
  type        = number
  default     = null
}

variable "peer_inactivity_expiration_enabled" {
  description = "Enables or disables peer inactivity expiration globally"
  type        = bool
  default     = null
}

variable "peer_login_expiration" {
  description = "Period of time after which peer login expires (seconds)"
  type        = number
  default     = null
}

variable "peer_login_expiration_enabled" {
  description = "Enables or disables peer login expiration globally"
  type        = bool
  default     = null
}

variable "regular_users_view_blocked" {
  description = "Allows blocking regular users from viewing parts of the system"
  type        = bool
  default     = null
}

variable "routing_peer_dns_resolution_enabled" {
  description = "Enables or disables DNS resolution on routing peers"
  type        = bool
  default     = null
}

variable "user_approval_required" {
  description = "Enables manual approval for new users joining via domain matching"
  type        = bool
  default     = null
}
