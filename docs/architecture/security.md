# Security Architecture

## 1. Network Boundaries
- **Public**: ALB (443/TCP) and STUN (3478/UDP).
- **Private**: EKS Cluster, NetBird internal ports, PostgreSQL.
- **Database Exposure**: PostgreSQL is entirely internal, listening on 5432/TCP within the EKS private network, accessible only to NetBird pods.

## 2. Secrets Management
- **No Git Commitment**: Secrets (passwords, PATs, OIDC secrets, private keys) are explicitly excluded via `.gitignore`.
- **Secret Storage**: Initially managed via Kubernetes Secrets. 
- **Evolution Path**: Future migration to AWS Secrets Manager using External Secrets Operator (ESO) without application changes.
- **Terraform State**: Remote S3 backend must enforce encryption-at-rest and strict IAM access control. State is not tracked in Git.

## 3. Bootstrap Authentication
- The initial NetBird setup uses `NB_SETUP_PAT_ENABLED=true` to expose an unauthenticated `/api/setup` endpoint.
- **Security Control**: This endpoint must be accessed immediately upon startup, the generated Personal Access Token (PAT) securely stored, and the flag disabled (`NB_SETUP_PAT_ENABLED=false`) with a server restart to close the endpoint.

## 4. Kubernetes Hardening
- Workloads are evaluated for `runAsNonRoot`, `readOnlyRootFilesystem`, and dropped capabilities.
- Liveness and readiness probes are configured using the internal `9000/TCP` health endpoint.
