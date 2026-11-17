resource "netbird_dns_record" "this" {
  for_each = var.items

  content = each.value.content
  name    = each.value.name
  ttl     = each.value.ttl
  type    = each.value.type
  zone_id = coalesce(each.value.zone_id, var.zone_id)
}

