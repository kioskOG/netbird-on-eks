resource "netbird_group" "this" {
  for_each = var.items

  name      = each.value.name
  peers     = each.value.peers
  resources = each.value.resources
}
