resource "netbird_reverse_proxy_domain" "this" {
  for_each = var.items

  domain         = each.value.domain
  target_cluster = each.value.target_cluster
}
