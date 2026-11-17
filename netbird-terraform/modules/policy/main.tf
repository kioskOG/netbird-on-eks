resource "netbird_policy" "this" {
  for_each = var.items

  description           = each.value.description
  enabled               = each.value.enabled
  name                  = each.value.name
  source_posture_checks = each.value.source_posture_checks

  dynamic "rule" {
    for_each = each.value.rule != null ? each.value.rule : []
    content {
      action               = rule.value.action
      authorized_groups    = rule.value.authorized_groups
      bidirectional        = rule.value.bidirectional
      description          = rule.value.description
      destination_resource = rule.value.destination_resource
      destinations         = rule.value.destinations
      enabled              = rule.value.enabled
      name                 = rule.value.name
      port_ranges          = rule.value.port_ranges
      ports                = rule.value.ports
      protocol             = rule.value.protocol
      source_resource      = rule.value.source_resource
      sources              = rule.value.sources
    }
  }
}
