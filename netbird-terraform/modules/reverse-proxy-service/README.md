# NetBird Reverse Proxy Service Module

Manages L7 HTTP and L4 passthrough services (`netbird_reverse_proxy_service`) exposed through the NetBird reverse proxy.

## Architecture
- **Type**: Collection (`var.items`)
- **Resource**: `netbird_reverse_proxy_service`

## Security Considerations
- Authentication passwords, PINs, header values, and custom headers are marked sensitive.
- `var.items` and `output.items` are marked `sensitive = true`.
- Use `reverse_proxy_service_ids` and `reverse_proxy_service_metadata` for non-sensitive references.

## Inputs

| Name | Type | Description | Default |
|------|------|-------------|---------|
| `items` | `map(object)` | Map of service configurations (Sensitive) | `{}` |

### Item Attributes

- `name` (`string`, required): Service name.
- `domain` (`string`, required): Ingress domain.
- `mode` (`string`, optional): `"http"` (L7 proxy), `"tcp"`, `"udp"`, or `"tls"` (L4).
- `listen_port` (`number`, optional): Port proxy listens on (0 for auto-assignment).
- `enabled` (`bool`, optional): Whether service is active.
- `pass_host_header` (`bool`, optional): Pass original client Host header.
- `rewrite_redirects` (`bool`, optional): Rewrite Location headers in backend responses.
- `access_restrictions` (`object`, optional): CIDR and country restrictions (`allowed_cidrs`, `allowed_countries`, etc.).
- `auth` (`object`, required): Authentication configuration (`bearer_auth`, `header_auths`, `link_auth`, `password_auth`, `pin_auth`).
- `targets` (`list(object)`, required): Backend targets (`target_id`, `target_type`, `protocol`, `port`, `options`).

## Outputs

| Name | Sensitive | Description |
|------|:---------:|-------------|
| `reverse_proxy_service_ids` | No | Map of service keys to IDs |
| `reverse_proxy_service_metadata` | No | Non-sensitive metadata (names, domains, modes, ports) |
| `name_to_id` | No | Map of service names to IDs |

## Example Usage

```hcl
module "proxy_services" {
  source = "../../modules/reverse-proxy-service"

  items = {
    "dashboard" = {
      name   = "Internal Dashboard"
      domain = "dash.vpn.example.com"
      mode   = "http"
      auth = {
        bearer_auth = {
          enabled             = true
          distribution_groups = [module.groups.group_ids["devs"]]
        }
      }
      targets = [
        {
          target_id   = module.peers.peer_ids["web-server"]
          target_type = "peer"
          protocol    = "http"
          port        = 8080
        }
      ]
    }
  }
}
```
