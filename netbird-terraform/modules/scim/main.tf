resource "netbird_scim" "this" {
  provider_name       = var.provider_name
  enabled             = var.enabled
  prefix              = var.prefix
  group_prefixes      = var.group_prefixes
  user_group_prefixes = var.user_group_prefixes
}
