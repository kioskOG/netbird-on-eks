resource "netbird_identity_provider" "this" {
  name          = var.name
  type          = var.type
  issuer        = var.issuer
  client_id     = var.client_id
  client_secret = var.client_secret
}
