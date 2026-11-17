variable "release_namespace" {
  type    = string
  default = "external-secrets"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "chart_version" {
  type    = string
  default = "0.9.14" # Standard recent version, overridden in live
}

variable "service_account_name" {
  type    = string
  default = "external-secrets"
}

variable "service_account_role_arn" {
  type        = string
  description = "The ARN of the IAM role for IRSA"
}
