include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../..//netbird-terraform/modules/posture-check"
}

inputs = {
  items = {
    "compliance_baseline" = {
      name        = "compliance-dev-baseline"
      description = "Baseline device compliance requirements"
      netbird_version_check = {
        min_version = "0.28.0"
      }
      os_version_check = {
        linux_min_kernel_version = "5.15.0"
        darwin_min_version       = "13.0.0"
      }
      peer_network_range_check = {
        action = "allow"
        ranges = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
      }
    }
  }
}
