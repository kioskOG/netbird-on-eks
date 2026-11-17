resource "netbird_agent_network_settings" "this" {
  access_log_retention_days = var.access_log_retention_days
  enable_log_collection     = var.enable_log_collection
  enable_prompt_collection  = var.enable_prompt_collection
  endpoint                  = var.endpoint
  proxy_address             = var.proxy_address
  redact_pii                = var.redact_pii
}
