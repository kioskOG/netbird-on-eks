resource "netbird_network_resource" "this" {
  for_each = var.items

  # NetBird management server normalizes host IPv4 addresses to CIDR /32.
  # Normalizing single IPv4 addresses here prevents Terraform "Provider produced inconsistent result after apply" errors.
  address     = can(regex("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}$", each.value.address)) ? "${each.value.address}/32" : each.value.address
  description = each.value.description
  enabled     = each.value.enabled
  groups      = each.value.groups
  name        = each.value.name
  network_id  = coalesce(each.value.network_id, var.network_id)
}

