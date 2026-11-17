# Network Topology

*(This document supplements `networking.md`)*

## Internal Network (VPC)

- **VPC**: Creates an isolated network boundary.
- **Subnets**: Public (for ALB/NAT) and Private (for EKS Nodes and PostgreSQL).
- **Security Groups**:
  - `alb-sg`: Allows 443/TCP from Internet.
  - `eks-node-sg`: Allows traffic from `alb-sg` to NodePorts, plus 3478/UDP from Internet.
  - `postgres-sg`: Allows 5432/TCP from EKS Pod CIDR only.

## Service Ports

| Service | Internal Port | Protocol | Purpose |
|---|---|---|---|
| Management | 8081 | TCP | API, gRPC, WebSocket |
| Signal | 8083 | TCP | gRPC, WebSocket |
| Relay | 8084 | TCP | WebSocket |
| STUN | 3478 | UDP | NAT Traversal |
| Dashboard | 80 | TCP | Web UI |
| PostgreSQL | 5432 | TCP | Datastore |
| Metrics | 9090 | TCP | Prometheus |
| Health | 9000 | TCP | Liveness/Readiness |
