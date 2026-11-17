variable "provider_name" {
  description = "Name of the SCIM identity provider (e.g. okta, azure-ad, keycloak)"
  type        = string
}

variable "enabled" {
  description = "Indicates whether the integration is enabled"
  type        = bool
  default     = true
}

variable "prefix" {
  description = "The connection prefix used for the SCIM provider"
  type        = string
  default     = null
}

variable "group_prefixes" {
  description = "List of start_with string patterns for groups to sync"
  type        = list(string)
  default     = null
}

variable "user_group_prefixes" {
  description = "List of start_with string patterns for groups which users to sync"
  type        = list(string)
  default     = null
}
