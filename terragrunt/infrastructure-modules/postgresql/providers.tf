provider "helm" {
  kubernetes {
    config_path = "~/.kube/netbird"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/netbird"
}
