# NetBird Account Settings Module

This module manages the account-wide configuration singleton (`netbird_account_settings`) for a NetBird tenant.

## Architecture
- **Type**: Singleton
- **Resource**: `netbird_account_settings`

Only one account settings resource exists per NetBird account. This module exposes flat, root-level inputs instead of collection maps.

## Inputs

| Name | Type | Description | Default |
|------|------|-------------|---------|
| `auto_update_version` | `string` | Client auto-update version (`"latest"`, `"disabled"`, or version string) | `null` |
| `dns_domain` | `string` | Custom DNS domain for the account | `null` |
| `groups_propagation_enabled` | `bool` | Propagate new user auto groups to user-owned peers | `null` |
| `jwt_allow_groups` | `list(string)` | List of groups allowed access via JWT claims | `null` |
| `jwt_groups_claim_name` | `string` | JWT claim name to extract groups from | `null` |
| `jwt_groups_enabled` | `bool` | Extract groups from JWT claims into account groups | `null` |
| `lazy_connection_enabled` | `bool` | Enable experimental lazy connection | `null` |
| `network_range` | `string` | Custom network range in CIDR format | `null` |
| `network_traffic_logs_enabled` | `bool` | Enable network traffic logging | `null` |
| `network_traffic_logs_groups` | `list(string)` | Limit traffic logging to specified group IDs | `null` |
| `network_traffic_packet_counter_enabled` | `bool` | Enable packet and byte counters | `null` |
| `peer_approval_enabled` | `bool` | Enable peer approval globally (Cloud only) | `null` |
| `peer_expose_enabled` | `bool` | Allow peers to expose local services via reverse proxy CLI | `null` |
| `peer_expose_groups` | `list(string)` | Limit peer expose capability to specific groups | `null` |
| `peer_inactivity_expiration` | `number` | Inactivity expiration in seconds | `null` |
| `peer_inactivity_expiration_enabled` | `bool` | Enable peer inactivity expiration | `null` |
| `peer_login_expiration` | `number` | Login expiration period in seconds | `null` |
| `peer_login_expiration_enabled` | `bool` | Enable peer login expiration | `null` |
| `regular_users_view_blocked` | `bool` | Block regular users from viewing parts of the system | `null` |
| `routing_peer_dns_resolution_enabled` | `bool` | Enable DNS resolution on routing peers | `null` |
| `user_approval_required` | `bool` | Require admin approval for users joining via domain matching | `null` |

## Outputs

| Name | Description |
|------|-------------|
| `id` | Account unique identifier |
| `account_id` | Account identifier (alias for `id`) |

## Example Usage

```hcl
module "account_settings" {
  source = "../../modules/account-settings"

  peer_login_expiration_enabled      = true
  peer_login_expiration              = 86400
  peer_inactivity_expiration_enabled = false
  peer_approval_enabled               = false
  groups_propagation_enabled         = true
  routing_peer_dns_resolution_enabled = true
}
```

---

## Import Existing Account Settings

Because NetBird automatically initializes default account settings upon installation, existing installations should be imported into Terraform state rather than recreated.

> [!NOTE]
> **Self-Hosted vs. Cloud NetBird**:
> In **Self-Hosted NetBird**, the Web Dashboard does not display an Account ID because the installation is single-tenant. However, NetBird's management server and database still assign an internal Account ID that the Terraform provider requires for `terraform import`.

### Step 1: Retrieve the Internal Account ID

Query the NetBird Management API using your Admin Personal Access Token (`NB_PAT`):

```bash
# Ensure your NetBird Management URL and Admin PAT are exported
export NB_URL="https://netbird.REPLACE_ME_DOMAIN"
export NB_PAT="<your-netbird-admin-pat>"

# Retrieve internal Account ID from Management API
ACCOUNT_ID=$(curl -s -f \
  -H "Authorization: Token ${NB_PAT}" \
  -H "Accept: application/json" \
  "${NB_URL}/api/accounts" | jq -r '.[0].id')

echo "NetBird Account ID: ${ACCOUNT_ID}"
```


# In case of Self hosted Netbird
```bash
ACCOUNT_ID=$(curl -s -f \
  -H "Authorization: Token ${NB_PAT}" \
  "https://netbird.REPLACE_ME_DOMAIN/api/accounts" | jq -r '.[0].id')

echo "NetBird Account ID: ${ACCOUNT_ID}"
```

#### *(Alternative for Kubernetes / EKS)*: If API access is restricted from your terminal, query the self-hosted PostgreSQL database directly:

```bash
ACCOUNT_ID=$(kubectl exec -n netbird -c postgres \
  $(kubectl get pod -n netbird -l cnpg.io/cluster=netbird-pg -o jsonpath='{.items[0].metadata.name}') \
  -- psql -U netbird -d netbird -t -A -c "SELECT id FROM accounts LIMIT 1;")
```

---

### Step 2: Run `terragrunt import`

Navigate to your [account-settings Terragrunt unit](../../../terragrunt/netbird-live/accounts/netbird/dev/account-settings/terragrunt.hcl) and run the import command:

```bash
cd ../../../terragrunt/netbird-live/accounts/netbird/dev/account-settings

terragrunt import netbird_account_settings.this "${ACCOUNT_ID}"
```

> [!NOTE]
> The resource target address is `netbird_account_settings.this` because Terragrunt sources this module as the root module of the unit. For standalone Terraform module usage, use `module.<name>.netbird_account_settings.this`.

---

### Step 3: Verify and Reconcile with `terragrunt plan`

After the import succeeds, run a plan to check for differences between what was imported and the inputs declared in [terragrunt.hcl](../../../terragrunt/netbird-live/accounts/netbird/dev/account-settings/terragrunt.hcl):

```bash
terragrunt plan
```

- **If diffs appear**: 
  - Update `inputs = { ... }` in [terragrunt.hcl](../../../terragrunt/netbird-live/accounts/netbird/dev/account-settings/terragrunt.hcl) to match live settings if you want to retain current settings.
  - Run `terragrunt apply` if you wish to enforce your declarative HCL configuration over the live settings.

---

### All-in-One Command

You can run the lookup, import, and verification together in a single command:

```bash
cd ../../../terragrunt/netbird-live/accounts/netbird/dev/account-settings

ACCOUNT_ID=$(curl -s -f -H "Authorization: Token ${NB_PAT}" https://netbird.REPLACE_ME_DOMAIN/api/accounts | jq -r '.[0].id') && \
terragrunt import netbird_account_settings.this "${ACCOUNT_ID}" && \
terragrunt plan
```
