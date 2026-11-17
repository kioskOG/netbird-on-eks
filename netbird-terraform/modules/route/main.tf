resource "netbird_route" "this" {
  for_each = var.items

  access_control_groups = each.value.access_control_groups
  description           = each.value.description
  domains               = each.value.domains
  enabled               = each.value.enabled
  groups                = each.value.groups
  keep_route            = each.value.keep_route
  masquerade            = each.value.masquerade
  metric                = each.value.metric
  network               = each.value.network
  network_id            = coalesce(each.value.network_id, var.network_id)
  peer                  = each.value.peer
  peer_groups           = each.value.peer_groups
  skip_auto_apply       = each.value.skip_auto_apply
}
