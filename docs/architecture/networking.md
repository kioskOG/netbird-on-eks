# Network & Traffic Flow

## Ingress Architecture

All TCP HTTP/HTTPS traffic flows through a single AWS Application Load Balancer (ALB). 
UDP traffic (STUN) flows directly to EKS nodes via NodePort.

```text
                         Internet
                            |
                         Route53
                            |
                         AWS ALB (ACM TLS :443)
                            |
              +-------------+-------------+
              |                           |
              v                           v
        NetBird Dashboard          NetBird Server
       (Internal Port 80)          (Internal Ports:
                                    8081 - Management
                                    8083 - Signal
                                    8084 - Relay)
```

## ALB Routing Configuration

The ALB uses path-based routing to direct traffic to different target groups:

| Path Pattern | Target Port | Protocol Requirement |
|---|---|---|
| `/api/*` | 8081 | HTTP/REST |
| `/ws-proxy/management*` | 8081 | HTTP + WebSocket upgrade |
| `/management.ManagementService/*` | 8081 | gRPC (h2c / HTTP/2) |
| `/oauth2/*` | 8081 | HTTP |
| `/ws-proxy/signal*` | 8083 | HTTP + WebSocket upgrade |
| `/signalexchange.SignalExchange/*` | 8083 | gRPC (h2c / HTTP/2) |
| `/relay*` | 8084 | HTTP + WebSocket upgrade |
| `/*` (catch-all) | 80 | HTTP (Dashboard) |

**Note on gRPC:** The target groups for gRPC traffic MUST have their Protocol Version set to `GRPC`.

## STUN (UDP) Architecture

ALB does not support UDP. The embedded STUN server requires direct UDP access:
- **Port**: 3478/UDP
- **Exposure**: Kubernetes NodePort
- **Security**: AWS Security Group allows inbound UDP 3478 from `0.0.0.0/0` to EKS nodes.
