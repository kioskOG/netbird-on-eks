
resource "helm_release" "cloudnative_pg" {
  name       = "cnpg"
  repository = "https://cloudnative-pg.github.io/charts"
  chart      = "cloudnative-pg"
  version    = var.cnpg_chart_version
  namespace  = var.cnpg_namespace

  create_namespace = true
}

resource "kubernetes_manifest" "netbird_pg_external_secret" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "netbird-pg-credentials"
      namespace = var.namespace
    }
    spec = {
      refreshInterval = "1h"
      secretStoreRef = {
        name = var.cluster_secret_store_name
        kind = "ClusterSecretStore"
      }
      target = {
        name           = "netbird-pg-app"
        creationPolicy = "Owner"
      }
      data = [
        {
          secretKey = "username"
          remoteRef = {
            key      = var.aws_secret_name
            property = "username"
          }
        },
        {
          secretKey = "password"
          remoteRef = {
            key      = var.aws_secret_name
            property = "password"
          }
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "netbird_postgresql_cluster" {
  depends_on = [
    helm_release.cloudnative_pg,
    kubernetes_manifest.netbird_pg_external_secret
  ]

  manifest = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "Cluster"
    metadata = {
      name      = var.cluster_name
      namespace = var.namespace
    }
    spec = {
      instances = var.instances

      # Recommended to use 16 as per standard PG versions.
      imageName = "ghcr.io/cloudnative-pg/postgresql:16"

      storage = {
        size         = var.storage_size
        storageClass = var.storage_class
      }

      bootstrap = {
        initdb = {
          database = var.database_name
          owner    = var.database_owner
          secret = {
            name = "netbird-pg-app"
          }
        }
      }
    }
  }
}
