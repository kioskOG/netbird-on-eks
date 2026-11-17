mock_provider "netbird" {}

run "accepts_valid_rule" {
  command = plan

  variables {
    items = {
      web = {
        name = "devops -> web"
        rule = [{
          name         = "https"
          action       = "accept"
          protocol     = "tcp"
          sources      = ["grp-a"]
          destinations = ["grp-b"]
          ports        = ["443"]
        }]
      }
    }
  }

  assert {
    condition     = length(netbird_policy.this) == 1
    error_message = "Expected one policy."
  }
}

run "rejects_unknown_action" {
  command = plan

  variables {
    items = {
      bad = {
        name = "bad"
        rule = [{ name = "r", action = "allow", protocol = "tcp", sources = ["a"], destinations = ["b"] }]
      }
    }
  }

  expect_failures = [var.items]
}

run "rejects_unknown_protocol" {
  command = plan

  variables {
    items = {
      bad = {
        name = "bad"
        rule = [{ name = "r", action = "accept", protocol = "http", sources = ["a"], destinations = ["b"] }]
      }
    }
  }

  expect_failures = [var.items]
}
