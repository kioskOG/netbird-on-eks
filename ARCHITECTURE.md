# NetBird Self-Hosted Platform Architecture

This repository manages a self-hosted NetBird platform using an infrastructure-as-code approach. 
The platform is deployed on AWS EKS and managed via Terraform and Terragrunt.

## Architectural Principles
1. **Everything as Code**: Infrastructure and NetBird configuration are fully automated via Terraform.
2. **Reproducible**: Can be completely restored from Git + Secrets + DB Backup.
3. **Database Abstraction**: NetBird is decoupled from the underlying database (Kubernetes Postgres initially, RDS supported later).
4. **Secure by Default**: NodePort restricted, ALB TLS, internal DB, externalized secrets.
5. **Separation of Concerns**: State is partitioned to limit blast radius (Network, EKS, NetBird, Config).

For detailed documentation, please refer to the `docs/architecture/` directory:
- [Overview](docs/architecture/overview.md)
- [Networking](docs/architecture/networking.md)
- [Security](docs/architecture/security.md)
- [Recovery](docs/architecture/recovery.md)
