mock_provider "netbird" {}

run "accepts_service_user" {
  command = plan

  variables {
    items = {
      bot = { name = "ci-bot", is_service_user = true, role = "network_admin" }
    }
  }

  assert {
    condition     = netbird_user.this["bot"].is_service_user
    error_message = "is_service_user must be passed through."
  }
}

run "rejects_unknown_role" {
  command = plan

  variables {
    items = {
      bad = { name = "x", is_service_user = true, role = "superuser" }
    }
  }

  expect_failures = [var.items]
}
