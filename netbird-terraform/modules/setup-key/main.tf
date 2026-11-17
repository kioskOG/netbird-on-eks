resource "netbird_setup_key" "this" {
  for_each = var.items

  allow_extra_dns_labels = each.value.allow_extra_dns_labels
  auto_groups            = each.value.auto_groups
  ephemeral              = each.value.ephemeral
  expiry_seconds         = each.value.expiry_seconds
  name                   = each.value.name
  revoked                = each.value.revoked
  type                   = each.value.type
  usage_limit            = each.value.usage_limit
}
