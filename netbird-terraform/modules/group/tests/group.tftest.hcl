# Offline unit tests: run `terraform init -backend=false && terraform test` in this module.
mock_provider "netbird" {}

run "creates_one_group_per_item_and_maps_ids" {
  command = apply

  variables {
    items = {
      web = { name = "svc-web" }
      db  = { name = "svc-db" }
    }
  }

  assert {
    condition     = length(netbird_group.this) == 2
    error_message = "Expected one netbird_group per item."
  }

  assert {
    condition     = keys(output.group_ids) == ["db", "web"] && contains(keys(output.name_to_id), "svc-web")
    error_message = "group_ids must be keyed by item key and name_to_id by group name."
  }
}

run "empty_items_creates_nothing" {
  command = plan

  assert {
    condition     = length(netbird_group.this) == 0
    error_message = "Default items = {} must not create groups."
  }
}
