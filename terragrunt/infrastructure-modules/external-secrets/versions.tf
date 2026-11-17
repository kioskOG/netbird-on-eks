terraform {
  required_version = ">= 1.0.0"
  backend "s3" {}
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.14.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30.0"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/netbird"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/netbird"
}
