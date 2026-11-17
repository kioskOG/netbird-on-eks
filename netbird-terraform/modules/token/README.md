# NetBird Personal Access Token Module

Manages Personal Access Tokens (`netbird_token`) for authenticating API operations.

## Architecture
- **Type**: Collection (`var.items`)
- **Resource**: `netbird_token`

## Security Considerations
- Generated PAT strings (`netbird_token.token`) are sensitive credentials.
- `output.tokens` and `output.items` are marked `sensitive = true`.
- Non-sensitive metadata (`token_ids`, `token_metadata`, `name_to_id`) are exported separately.

## Inputs

| Name | Type | Description | Default |
|------|------|-------------|---------|
| `items` | `map(object)` | Map of token definitions | `{}` |

### Item Attributes

- `name` (`string`, required): Token name / description.
- `expiration_days` (`number`, required): Token expiration period in days.
- `user_id` (`string`, required): Target user ID for whom the token is generated.

## Outputs

| Name | Sensitive | Description |
|------|:---------:|-------------|
| `token_ids` | No | Map of token keys to IDs |
| `token_metadata` | No | Non-sensitive metadata (created date, expiration date, user ID) |
| `name_to_id` | No | Map of token names to IDs |
| `tokens` | **Yes** | Map of token keys to sensitive plaintext PATs |

## Example Usage

```hcl
module "tokens" {
  source = "../../modules/token"

  items = {
    "ci_token" = {
      name            = "gitlab-ci-service-token"
      user_id         = module.users.user_ids["ci_service_user"]
      expiration_days = 90
    }
  }
}
```
