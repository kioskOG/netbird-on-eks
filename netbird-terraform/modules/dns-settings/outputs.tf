output "disabled_management_groups" {
  description = "Groups whose DNS management is disabled"
  value       = netbird_dns_settings.this.disabled_management_groups
}

