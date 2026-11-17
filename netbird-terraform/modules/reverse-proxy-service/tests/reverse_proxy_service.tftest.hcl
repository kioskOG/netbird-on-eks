mock_provider "netbird" {}

variables {
  base = {
    name    = "svc"
    domain  = "proxy.example.com"
    auth    = { bearer_auth = { enabled = true } }
    targets = [{ target_id = "peer-1", target_type = "peer", protocol = "http", port = 8080 }]
  }
}

run "accepts_http_mode" {
  command = plan

  variables {
    items = { svc = merge(var.base, { mode = "http" }) }
  }

  assert {
    condition     = length(netbird_reverse_proxy_service.this) == 1
    error_message = "Expected one reverse proxy service."
  }
}

run "rejects_unknown_mode" {
  command = plan

  variables {
    items = { svc = merge(var.base, { mode = "grpc" }) }
  }

  expect_failures = [var.items]
}
