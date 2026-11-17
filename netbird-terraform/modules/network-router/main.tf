resource "netbird_network_router" "this" {
  for_each = var.items

  enabled     = each.value.enabled
  masquerade  = each.value.masquerade
  metric      = each.value.metric
  network_id  = coalesce(each.value.network_id, var.network_id)
  peer        = each.value.peer
  peer_groups = each.value.peer_groups
}
