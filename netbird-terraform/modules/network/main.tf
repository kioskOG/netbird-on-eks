resource "netbird_network" "this" {
  for_each = var.items

  description = each.value.description
  name        = each.value.name
}
