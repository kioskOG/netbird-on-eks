mock_provider "netbird" {}

run "module_level_zone_id_is_used" {
  command = plan

  variables {
    zone_id = "zone-1"
    items = {
      api = { name = "api.example.internal", type = "A", content = "100.64.0.10" }
    }
  }

  assert {
    condition     = netbird_dns_record.this["api"].zone_id == "zone-1"
    error_message = "Records without zone_id must fall back to the module-level zone_id."
  }
}

run "rejects_unsupported_type" {
  command = plan

  variables {
    zone_id = "zone-1"
    items = {
      bad = { name = "x.example.internal", type = "MX", content = "mail" }
    }
  }

  expect_failures = [var.items]
}

run "requires_a_zone_id" {
  command = plan

  variables {
    items = {
      orphan = { name = "x.example.internal", type = "A", content = "100.64.0.1" }
    }
  }

  expect_failures = [var.items]
}
