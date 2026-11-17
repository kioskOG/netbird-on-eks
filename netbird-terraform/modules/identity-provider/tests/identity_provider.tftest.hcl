mock_provider "netbird" {}

variables {
  name      = "sso"
  issuer    = "https://idp.example.com/realms/netbird"
  client_id = "netbird"
}

run "accepts_oidc_provider" {
  command = plan

  variables {
    client_secret = "not-a-real-secret"
  }

  assert {
    condition     = netbird_identity_provider.this.type == "oidc"
    error_message = "type must default to oidc."
  }
}

run "rejects_empty_client_secret" {
  command = plan

  variables {
    client_secret = ""
  }

  expect_failures = [var.client_secret]
}

run "rejects_unknown_type" {
  command = plan

  variables {
    type          = "keycloak"
    client_secret = "not-a-real-secret"
  }

  expect_failures = [var.type]
}
