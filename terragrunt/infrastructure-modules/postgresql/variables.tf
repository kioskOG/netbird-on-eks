variable "cnpg_chart_version" {
  description = "Version of the CloudNativePG Helm chart"
  type        = string
  default     = "0.29.1"
}

variable "namespace" {
  description = "Namespace for the PostgreSQL cluster"
  type        = string
  default     = "netbird"
}

variable "cnpg_namespace" {
  description = "Namespace for CloudNativePG operator"
  type        = string
  default     = "cnpg-system"
}

variable "cluster_name" {
  description = "Name of the PostgreSQL cluster"
  type        = string
  default     = "netbird-postgresql"
}

variable "instances" {
  description = "Number of PostgreSQL instances"
  type        = number
  default     = 1
}

variable "storage_size" {
  description = "Size of the PostgreSQL persistent volume"
  type        = string
  default     = "20Gi"
}

variable "storage_class" {
  description = "Storage class for the PostgreSQL persistent volume"
  type        = string
  default     = "gp2"
}

variable "database_name" {
  description = "Name of the initial database"
  type        = string
  default     = "netbird"
}

variable "database_owner" {
  description = "Owner of the initial database"
  type        = string
  default     = "netbird"
}

variable "aws_secret_name" {
  description = "Name of the AWS Secret Manager secret"
  type        = string
}

variable "cluster_secret_store_name" {
  description = "Name of the ClusterSecretStore to use"
  type        = string
  default     = "aws-secretsmanager"
}
