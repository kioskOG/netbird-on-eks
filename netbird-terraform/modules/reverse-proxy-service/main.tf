resource "netbird_reverse_proxy_service" "this" {
  for_each = var.items

  access_restrictions = each.value.access_restrictions
  auth                = each.value.auth
  domain              = each.value.domain
  enabled             = each.value.enabled
  listen_port         = each.value.listen_port
  mode                = each.value.mode
  name                = each.value.name
  pass_host_header    = each.value.pass_host_header
  rewrite_redirects   = each.value.rewrite_redirects
  targets             = each.value.targets
}
