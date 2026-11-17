# NetBird Identity Provider Module

Manages the primary OAuth2/OIDC identity provider integration (`netbird_identity_provider`) for NetBird authentication.

## Architecture
- **Type**: Singleton
- **Resource**: `netbird_identity_provider`

## Security Considerations
- `client_secret` input is marked `sensitive = true`.
- `client_secret` is **explicitly omitted** from module outputs to prevent leakage into downstream state or console outputs.
- Non-sensitive metadata (`id`, `name`, `type`, `issuer`, `client_id`) are exported separately.
- In Terragrunt live deployments, **Pattern A (Dynamic Ingestion from AWS Secrets Manager)** is used to fetch `client_secret` in-memory at runtime without committing credentials to Git.

## Inputs

| Name | Type | Sensitive | Description | Default |
|------|------|:---------:|-------------|---------|
| `name` | `string` | No | Display name (e.g. `"Keycloak"`) | - |
| `type` | `string` | No | Provider type (`"entra"`, `"google"`, `"microsoft"`, `"oidc"`, `"okta"`, `"pocketid"`, `"zitadel"`) | `"oidc"` |
| `issuer` | `string` | No | OIDC issuer URL | - |
| `client_id` | `string` | No | OAuth2 client ID | - |
| `client_secret` | `string` | **Yes** | OAuth2 client secret | - |

## Outputs

| Name | Sensitive | Description |
|------|:---------:|-------------|
| `id` | No | Identity provider ID |
| `name` | No | Display name |
| `type` | No | Provider type |
| `issuer` | No | Issuer URL |
| `client_id` | No | Client ID |

## Example Usage (Keycloak SSO)

```hcl
module "sso" {
  source = "../../modules/identity-provider"

  name          = "Keycloak"
  type          = "oidc"
  issuer        = "https://keycloak.example.com/realms/netbird"
  client_id     = "netbird-client"
  client_secret = var.keycloak_client_secret
}
```
