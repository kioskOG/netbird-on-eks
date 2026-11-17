# Phase 4A - Repository & Module Audit (Remediated)

## 1. Existing Infrastructure Modules
**Finding:** The `infrastructure-modules` directory contains foundational AWS modules (`vpc`, `eks`, `iam`, `security-groups`, `secrets`). There are currently no Kubernetes application-layer modules (e.g., PostgreSQL, NetBird) or Helm abstraction modules.
**Action:** New reusable Terraform modules must be created at `infrastructure-modules/postgresql` and `infrastructure-modules/netbird`.

## 2. Existing Infrastructure Live Structure & Region
**Finding:** The approved NetBird deployment region is explicitly `us-east-2`, following the organization's default AWS region. The existing MLOps structure under `us-east-2` will be used as a reference for repository conventions. However, specific MLOps values (VPC IDs, ARNs) are NOT to be blindly copied. NetBird will dynamically consume its own specific AWS infrastructure outputs (like `vpc` and `eks` dependencies) or prompt the user for requirements.

**Action:** We will deploy into `infrastructure-live/accounts/mlops/us-east-2/`. The application layer will follow:
- `us-east-2/postgresql/terragrunt.hcl`
- `us-east-2/netbird/server/terragrunt.hcl`
- `us-east-2/netbird/dashboard/terragrunt.hcl`

*Values copied from other projects must be strictly classified as: REUSABLE CONVENTION, SHARED INFRASTRUCTURE, MLOPS-SPECIFIC, NETBIRD-SPECIFIC, or MUST BE CREATED/PROVIDED BY USER.*

## 3. Helm & Kubernetes Conventions
**Finding:** There are no pre-existing Helm/Kubernetes Terraform modules in the repository to use as templates. The EKS cluster includes the `aws-ebs-csi-driver` addon, ensuring EBS persistent storage is available for stateful workloads.
**Action:** The new modules will utilize the official Terraform `helm` and `kubernetes` providers. The `postgresql` module will use the `bitnami/postgresql` Helm chart, fully parameterized to accept dynamic StorageClass inputs (defaulting to the AWS EBS CSI driver's default class, typically `gp2` or `gp3`).

## 4. Secrets Architecture
**Finding:** The initial proposal to directly inject Terraform `kubernetes_secret` resources is **NOT APPROVED** as it creates unnecessary secret exposure in Terraform state.
**Action:** The preferred architecture must be:
```text
AWS Secrets Manager -> External Secrets Operator (ESO) -> Kubernetes Secret
```
This architecture will apply to PostgreSQL credentials, NetBird DataStore encryption keys, and the NetBird bootstrap PAT. These values will not be committed to Git or stored in Terraform configuration/outputs.

## 5. External Secrets Operator (ESO) Status
**Finding:** A search of the repository reveals that an IAM IRSA role (`ESOSecretsManagerAccessPolicy`) exists for `external-secrets` under `global/iam/role/terragrunt.hcl`. However, the actual ESO Helm deployment and `ExternalSecret`/`SecretStore` CRDs are **DOES NOT EXIST** in the current Kubernetes footprint.
**Action:** We will **NOT** automatically install ESO in Phase 4B. ESO is documented as a required Kubernetes platform dependency that must be fulfilled by the user prior to deploying PostgreSQL or NetBird.

## 5. PostgreSQL Chart Version Verification
**Finding:** The verified requirement is PostgreSQL 16.4. The stable Bitnami chart version aligning with PostgreSQL 16.4.0 is `15.5.32`.
**Action:** The `infrastructure-modules/postgresql` module will strictly pin the Helm chart to `15.5.32` from the `https://charts.bitnami.com/bitnami` repository. `latest` tags will be rejected.

## Conclusion
The audit confirms the correct deployment region is `us-east-2`. The existing MLOps conventions are reused for structure but values are strictly compartmentalized. 

**Missing Prerequisite:** The preferred secrets architecture requires External Secrets Operator, which currently DOES NOT EXIST on the cluster. The user must deploy this platform dependency.

**Status:** PHASE 4A REMEDIATION COMPLETE. Pending user approval to proceed to Phase 4B.
