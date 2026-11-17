resource "netbird_nameserver_group" "this" {
  for_each = var.items

  description            = each.value.description
  domains                = each.value.domains
  enabled                = each.value.enabled
  groups                 = each.value.groups
  name                   = each.value.name
  nameservers            = each.value.nameservers
  primary                = each.value.primary
  search_domains_enabled = each.value.search_domains_enabled
}
