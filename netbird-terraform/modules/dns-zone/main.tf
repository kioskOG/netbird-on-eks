resource "netbird_dns_zone" "this" {
  for_each = var.items

  distribution_groups  = each.value.distribution_groups
  domain               = each.value.domain
  enable_search_domain = each.value.enable_search_domain
  enabled              = each.value.enabled
  name                 = each.value.name
}
