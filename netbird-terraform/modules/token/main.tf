resource "netbird_token" "this" {
  for_each = var.items

  expiration_days = each.value.expiration_days
  name            = each.value.name
  user_id         = each.value.user_id
}
