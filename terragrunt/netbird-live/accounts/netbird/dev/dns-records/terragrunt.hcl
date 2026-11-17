include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../../..//netbird-terraform/modules/dns-record"
}

dependency "dns_zones" {
  config_path = "../dns-zones"
  mock_outputs = {
    dns_zone_ids = {
      internal_mesh = "mock-zone-internal-mesh"
    }
  }
}

inputs = {
  zone_id = dependency.dns_zones.outputs.dns_zone_ids["internal_mesh"]

  items = {
    "orders_api" = {
      name    = "orders-api.dev.netbird.internal"
      type    = "A"
      content = "100.64.0.10"
      ttl     = 300
    }
    "db_primary" = {
      name    = "db-primary.dev.netbird.internal"
      type    = "A"
      content = "100.64.0.20"
      ttl     = 300
    }
  }
}
