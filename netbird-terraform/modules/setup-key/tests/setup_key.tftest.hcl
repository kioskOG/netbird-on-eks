mock_provider "netbird" {}

run "accepts_reusable_key" {
  command = plan

  variables {
    items = {
      nodes = { name = "setup-nodes", type = "reusable", expiry_seconds = 86400, auto_groups = ["grp-a"] }
    }
  }

  assert {
    condition     = netbird_setup_key.this["nodes"].type == "reusable"
    error_message = "Key type must be passed through."
  }
}

run "rejects_invalid_type" {
  command = plan

  variables {
    items = {
      bad = { name = "bad", type = "permanent" }
    }
  }

  expect_failures = [var.items]
}
