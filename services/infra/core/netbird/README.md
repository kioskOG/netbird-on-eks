# NetBird Helm chart

The full install order, secrets, DNS, certificate, and identity-provider steps are in the repository [README](../../../../README.md).

Custom chart for the NetBird 0.80 combined server (`netbirdio/netbird-server`) and dashboard. The upstream Helm repo still packages the older split management/signal/coturn layout.

Dev and prod are separate charts under `dev/` and `prod/`. Install from the environment directory:

```bash
helm upgrade --install netbird . \
  --namespace netbird \
  --create-namespace \
  -f values.yaml -f values.local.yaml
```

The server reads Postgres from the CloudNativePG app secret `netbird-pg-app` (database `netbird` on `netbird-postgresql-rw`). Embedded IdP state stays on the data volume because Dex uses its own database.

STUN is a UDP NLB. Peers are told to use `stun:<domain>:3478`, and the ALB for that domain does not forward UDP. UDP 3478 on the public name has to reach this NLB or NAT traversal fails.

Set `ingress.certificateArn` to the ACM certificate for the public domain. The HTTPS listener needs it.

## Gateway API (alternative to the Ingress)

The `networking.k8s.io/v1` Ingress API is not deprecated. What was retired is the community ingress-nginx controller, and this chart does not use it: the ALB comes from the AWS Load Balancer Controller. Gateway API is the newer option, and `templates/gateway.yaml` builds the same ALB with it. It is off by default (`gateway.enabled: false`).

| Ingress | Gateway API |
| --- | --- |
| 3 Ingresses in ALB group `netbird` | 1 `Gateway` = 1 ALB |
| `ssl-redirect: '443'` | `HTTPRoute` `netbird-redirect` on the `http` listener |
| `certificate-arn` annotation | `LoadBalancerConfiguration` `defaultCertificate` (`gateway.certificateArn`) |
| `netbird-http` (HTTP/1, health `/metrics` on 9090) | `HTTPRoute` `netbird-http` plus the `TargetGroupConfiguration` default |
| `netbird-grpc` (`backend-protocol-version: HTTP2`) | `HTTPRoute` `netbird-grpc` plus a `routeConfigurations` override set to `HTTP2` |
| `netbird-dashboard` (catch-all `/`) | `HTTPRoute` `netbird-dashboard` |
| `group.order` | Gateway API precedence: longest path wins, so `/` is matched last |

Before you enable it:

1. Install `services/infra/core/aws-alb-controller`. It runs controller v3.6.0, and its chart installs the Gateway API v1.6.3 CRDs and the `gateway.k8s.aws` CRDs. Check them with `kubectl get crd | grep gateway`.
2. Set `gateway.enabled: true`. You can leave the Ingress on at the same time, since each creates its own ALB. Point DNS at the Gateway ALB, then set `ingress.enabled: false`.

```bash
kubectl -n netbird get gateway,httproute
kubectl -n netbird get gateway netbird -o jsonpath='{.status.addresses[0].value}{"\n"}'
```

The STUN NLB (`service-stun.yaml`) does not change.
