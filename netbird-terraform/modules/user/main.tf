resource "netbird_user" "this" {
  for_each = var.items

  auto_groups     = each.value.auto_groups
  email           = each.value.email
  is_blocked      = each.value.is_blocked
  is_service_user = each.value.is_service_user
  name            = each.value.name
  role            = each.value.role
}
