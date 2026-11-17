include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../..//netbird-terraform/modules/dns-settings"
}

inputs = {
  # Dashboard: DNS > Settings > "Disable DNS management for these groups".
  # Peers in a listed group ignore every NetBird DNS zone and nameserver group,
  # so never list a group that dns-zones or nameserver-groups distribute to.
  disabled_management_groups = []
}
