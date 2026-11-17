terraform {
  required_version = ">= 1.5.0"

  required_providers {
    netbird = {
      source  = "netbirdio/netbird"
      version = "~> 0.0.11"
    }
  }
}
