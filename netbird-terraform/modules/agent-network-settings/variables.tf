variable "access_log_retention_days" {
  description = "Days to retain full access-log rows (0 or less = keep indefinitely). Omit to leave current value unchanged."
  type        = number
  default     = null
}

variable "enable_log_collection" {
  description = "Collect per-request access-log entries for this account. Omit to leave current value unchanged."
  type        = bool
  default     = null
}

variable "enable_prompt_collection" {
  description = "Master switch for request/response prompt capture. Omit to leave current value unchanged."
  type        = bool
  default     = null
}

variable "endpoint" {
  description = "Hostname agents call for this account (dedicated gateway). Mutually exclusive with proxy_address."
  type        = string
  default     = null
}

variable "proxy_address" {
  description = "Cluster address of proxy serving this gateway. Mutually exclusive with endpoint."
  type        = string
  default     = null
}

variable "redact_pii" {
  description = "Redact PII from captured prompts. Omit to leave current value unchanged."
  type        = bool
  default     = null
}
