variable "name" {
  description = "Human-readable name for the identity provider (e.g. Keycloak)"
  type        = string
}

variable "type" {
  description = "Type of identity provider (entra, google, microsoft, oidc, okta, pocketid, zitadel)"
  type        = string
  default     = "oidc"

  validation {
    condition     = contains(["entra", "google", "microsoft", "oidc", "okta", "pocketid", "zitadel"], var.type)
    error_message = "Identity provider type must be one of: entra, google, microsoft, oidc, okta, pocketid, zitadel."
  }
}


variable "issuer" {
  description = "OIDC issuer URL (e.g. https://keycloak.example.com/realms/master)"
  type        = string
}

variable "client_id" {
  description = "OAuth2 / OIDC client ID"
  type        = string
}

variable "client_secret" {
  description = "OAuth2 / OIDC client secret"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.client_secret) > 0
    error_message = "client_secret must not be empty."
  }
}
