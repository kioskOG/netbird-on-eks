output "eso_namespace" {
  description = "Namespace where ESO is deployed"
  value       = helm_release.external_secrets.namespace
}

output "eso_release_name" {
  description = "Helm release name"
  value       = helm_release.external_secrets.name
}

output "eso_chart_version" {
  description = "ESO Helm chart version"
  value       = helm_release.external_secrets.version
}

output "cluster_secret_store_name" {
  description = "Name of the ClusterSecretStore"
  value       = "aws-secretsmanager"
}
