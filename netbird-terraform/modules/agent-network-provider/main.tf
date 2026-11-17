resource "netbird_agent_network_provider" "this" {
  for_each = var.items

  api_key                 = each.value.api_key
  enabled                 = each.value.enabled
  extra_values            = each.value.extra_values
  identity_header_groups  = each.value.identity_header_groups
  identity_header_user_id = each.value.identity_header_user_id
  metadata_disabled       = each.value.metadata_disabled
  models                  = each.value.models
  name                    = each.value.name
  provider_id             = each.value.provider_id
  skip_tls_verification   = each.value.skip_tls_verification
  upstream_url            = each.value.upstream_url
}
