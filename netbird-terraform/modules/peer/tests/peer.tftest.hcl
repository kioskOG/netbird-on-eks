mock_provider "netbird" {}

run "explicit_id_skips_lookup" {
  command = plan

  variables {
    items = {
      laptop = { id = "peer-123", ssh_enabled = true }
    }
  }

  assert {
    condition     = length(data.netbird_peer.lookup) == 0
    error_message = "A peer with an explicit id must not trigger a data source lookup."
  }
}

run "name_triggers_lookup" {
  command = plan

  variables {
    items = {
      laptop = { name = "dev-laptop.local" }
    }
  }

  assert {
    condition     = length(data.netbird_peer.lookup) == 1
    error_message = "A peer without an id must be looked up."
  }
}

run "requires_an_identifier" {
  command = plan

  variables {
    items = {
      anonymous = { ssh_enabled = true }
    }
  }

  expect_failures = [var.items]
}
