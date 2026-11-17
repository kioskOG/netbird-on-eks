# External Secrets Operator — Architecture

## Overview

The External Secrets Operator (ESO) synchronizes secrets from AWS Secrets Manager
into Kubernetes Secrets, eliminating static AWS credentials in the cluster.

```text
AWS Secrets Manager
        ↓
IAM Role / IRSA
        ↓
External Secrets Operator  (v0.11.0)
        ↓
ClusterSecretStore          (aws-secretsmanager)
        ↓
ExternalSecret              (per application)
        ↓
Kubernetes Secret           (auto-created by ESO)
```

## Versions

| Component              | Version   | Verified |
|------------------------|-----------|----------|
| ESO Helm chart         | 0.11.0    | ✅       |
| ESO app version        | v0.11.0   | ✅       |
| Helm provider          | ~> 2.14.0 | ✅       |
| Kubernetes provider    | ~> 2.30.0 | ✅       |
| EKS Kubernetes         | 1.34      | ✅       |
| ESO API version        | v1beta1   | ✅       |

## Authentication

```text
EKS Pod
   ↓
ServiceAccount: external-secrets  (namespace: external-secrets)
   ↓
IRSA annotation: eks.amazonaws.com/role-arn
   ↓
IAM Role: ESOControllerServiceAccountRole
   ↓
IAM Policy: ESOSecretsManagerAccessPolicy
   ↓
AWS Secrets Manager  (GetSecretValue, DescribeSecret, ListSecrets)
```

### IAM Role Trust

- **Role ARN**: `arn:aws:iam::REPLACE_ME_AWS_ACCOUNT_ID:role/ESOControllerServiceAccountRole`
- **OIDC Provider**: `oidc.eks.us-east-2.amazonaws.com/id/FDD72AF22E091BC3D74042281525BA9A`
- **Trusted SA**: `system:serviceaccount:external-secrets:external-secrets`
- **No static AWS credentials** — purely IRSA-based

### IAM Policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
        "secretsmanager:ListSecrets"
      ],
      "Resource": "*"
    }
  ]
}
```

Status: **REUSABLE** — generic, not Wazuh-specific. Wildcard resource is acceptable
for a shared ESO role that serves multiple applications on the same cluster.

## Resource Ownership

| Resource                    | Owner                  | Location                                        |
|-----------------------------|------------------------|-------------------------------------------------|
| IAM Role                    | AWS / Terragrunt       | `global/iam/role/`                              |
| IAM Policy                  | AWS / Terragrunt       | `global/iam/role/policy/`                       |
| OIDC Provider               | AWS / EKS              | User-managed                                    |
| Helm Release (ESO)          | Terraform / Terragrunt | `infrastructure-modules/external-secrets/`      |
| ClusterSecretStore          | Terraform / Terragrunt | `infrastructure-modules/external-secrets/`      |
| ExternalSecret declarations | Terraform / Terragrunt | Per-application modules                         |
| Kubernetes Secrets          | ESO (runtime)          | Created automatically                           |
| Operational validation      | Scripts                | `scripts/make/external-secrets.sh`              |

## ClusterSecretStore

- **Name**: `aws-secretsmanager`
- **Kind**: `ClusterSecretStore` (cluster-scoped — usable by any namespace)
- **Provider**: AWS Secrets Manager
- **Region**: `us-east-2`
- **Auth**: JWT / IRSA via ServiceAccount `external-secrets` in namespace `external-secrets`

### Usage

Any application can reference this store in its `ExternalSecret`:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: my-app-secret
  namespace: my-app
spec:
  refreshInterval: 1m
  secretStoreRef:
    name: aws-secretsmanager
    kind: ClusterSecretStore
  target:
    name: my-app-k8s-secret
    creationPolicy: Owner
  data:
    - secretKey: password
      remoteRef:
        key: my-app/credentials
        property: password
```

## Wazuh Implementation Comparison

The Wazuh platform (`wazuh-setup` repository) has a similar ESO deployment.

| Component              | Wazuh (reference)                    | NetBird (this repo)              |
|------------------------|--------------------------------------|----------------------------------|
| ESO Helm chart         | `external-secrets/external-secrets`  | Same — reused                    |
| Helm repo              | `charts.external-secrets.io`         | Same — reused                    |
| IAM role name          | `ESOControllerServiceAccountRole`    | Same — reused                    |
| IAM policy             | `ESOSecretsManagerAccessPolicy`      | Same — reused                    |
| ESO namespace          | `external-secrets`                   | Same — reused                    |
| ServiceAccount         | `external-secrets`                   | Same — reused                    |
| ClusterSecretStore     | `aws-secrets-manager`                | `aws-secretsmanager` (Terraform) |
| ExternalSecrets        | Wazuh-specific (10 secrets)          | Per-application (Phase 4B+)      |
| Installation method    | `helm upgrade --install` (script)    | Terraform `helm_release`         |
| Operational scripts    | `scripts/make/external-secrets.sh`   | Adapted version                  |

**Reused from Wazuh**: IAM role, IAM policy, Helm chart, IRSA pattern, ClusterSecretStore pattern, `installCRDs=true` strategy, operational script structure.

**Generalized**: ClusterSecretStore is now Terraform-managed (not `sed` + `kubectl apply`). ESO deployment is IaC-driven.

**Wazuh-specific (NOT copied)**: Wazuh namespace, Wazuh ExternalSecrets (indexer-cred, dashboard-cred, etc.), Wazuh TLS secrets, Wazuh SAML secrets, Keycloak integration.

## Operational Commands

```bash
# Status overview
./scripts/make/external-secrets.sh status

# Wait for ESO to be fully ready
./scripts/make/external-secrets.sh wait

# Full validation (PASS/FAIL per check)
./scripts/make/external-secrets.sh validate
```
