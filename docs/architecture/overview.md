# Architecture Overview

## Components

The architecture consists of the following major components running on AWS EKS (`us-east-2`):

1. **NetBird Server**: The unified control and data plane (v0.80.0)
   - Management API (REST/gRPC)
   - Signal Service (gRPC/WebSocket)
   - Relay Service (WebSocket/QUIC)
   - STUN Service (UDP)
2. **NetBird Dashboard**: The web-based UI (v2.94.0)
3. **PostgreSQL**: The relational datastore for NetBird configuration and state.

## State and Layer Separation

Terraform state is strictly separated into Terragrunt layers:

```text
10-network           (VPC, Subnets, Routing)
    ↓
20-eks               (Kubernetes cluster, Node groups)
    ↓
30-postgresql        (StatefulSet, PVC, internal Service)
    +
40-acm               (TLS Certificates)
    ↓
50-alb               (Ingress Controller, Target Groups)
    ↓
60-netbird-platform  (NetBird Server + Dashboard Deployments)
    ↓
70-netbird-config    (NetBird API configuration via Terraform provider)
    ↓
80-monitoring        (Prometheus/Grafana)
```

## Production Evolution Path

This architecture establishes a "POC" scale (1 replica, internal PostgreSQL) but is **fully structurally prepared for production**. 
Evolution involves:
- Scaling `netbird-server` replicas.
- Migrating PostgreSQL to AWS RDS (updating DSN secret only).
- Migrating secrets to AWS Secrets Manager via External Secrets Operator.
