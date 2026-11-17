# Optional dynamic lookup for peers where the ID is not explicitly provided
data "netbird_peer" "lookup" {
  for_each = {
    for k, v in var.items : k => v
    if v.id == null
  }

  name = coalesce(each.value.lookup_name, each.value.name)
  ip   = each.value.lookup_ip
}

resource "netbird_peer" "this" {
  for_each = var.items

  id                            = each.value.id != null ? each.value.id : data.netbird_peer.lookup[each.key].id
  approval_required             = each.value.approval_required
  inactivity_expiration_enabled = each.value.inactivity_expiration_enabled
  login_expiration_enabled      = each.value.login_expiration_enabled
  name                          = each.value.name
  ssh_enabled                   = each.value.ssh_enabled
}
