resource "netbird_posture_check" "this" {
  for_each = var.items

  description = each.value.description
  name        = each.value.name

  dynamic "geo_location_check" {
    for_each = each.value.geo_location_check != null ? [each.value.geo_location_check] : []
    content {
      action    = geo_location_check.value.action
      locations = geo_location_check.value.locations
    }
  }

  dynamic "netbird_version_check" {
    for_each = each.value.netbird_version_check != null ? [each.value.netbird_version_check] : []
    content {
      min_version = netbird_version_check.value.min_version
    }
  }

  dynamic "os_version_check" {
    for_each = each.value.os_version_check != null ? [each.value.os_version_check] : []
    content {
      android_min_version        = os_version_check.value.android_min_version
      darwin_min_version         = os_version_check.value.darwin_min_version
      ios_min_version            = os_version_check.value.ios_min_version
      linux_min_kernel_version   = os_version_check.value.linux_min_kernel_version
      windows_min_kernel_version = os_version_check.value.windows_min_kernel_version
    }
  }

  dynamic "peer_network_range_check" {
    for_each = each.value.peer_network_range_check != null ? [each.value.peer_network_range_check] : []
    content {
      action = peer_network_range_check.value.action
      ranges = peer_network_range_check.value.ranges
    }
  }

  dynamic "process_check" {
    for_each = each.value.process_check != null ? each.value.process_check : []
    content {
      linux_path   = process_check.value.linux_path
      mac_path     = process_check.value.mac_path
      windows_path = process_check.value.windows_path
    }
  }
}
