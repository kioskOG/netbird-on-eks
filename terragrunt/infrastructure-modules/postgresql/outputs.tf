output "cnpg_namespace" {
  description = "Namespace where CNPG is deployed"
  value       = var.cnpg_namespace
}

output "cluster_name" {
  description = "Name of the PostgreSQL cluster"
  value       = var.cluster_name
}

output "cluster_namespace" {
  description = "Namespace of the PostgreSQL cluster"
  value       = var.namespace
}

output "postgresql_service_hostname" {
  description = "Hostname for the PostgreSQL read-write service"
  value       = "${var.cluster_name}-rw.${var.namespace}.svc.cluster.local"
}

output "postgresql_port" {
  description = "Port for the PostgreSQL service"
  value       = 5432
}
