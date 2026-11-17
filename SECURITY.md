# Security Policy

## Reporting a vulnerability

Please **do not open a public issue** for security problems.

Report privately through GitHub: **Security** tab → **Report a vulnerability**
(private vulnerability reporting). You will get an acknowledgement within 5 working days.

Include the affected path, a description of the impact, and steps to reproduce.

## Scope

In scope: the Terraform modules, Terragrunt configuration, Helm charts and scripts in this
repository (for example insecure defaults, secrets written to state or logs, overly broad IAM).

Out of scope: vulnerabilities in NetBird itself (report to
[netbirdio/netbird](https://github.com/netbirdio/netbird/security)), Terraform, Terragrunt,
or AWS services.

## Handling secrets with this project

- Supply the NetBird admin token only through the `NB_PAT` environment variable.
- Terraform state for the `setup-keys` and `tokens` units contains secret values. Use an
  encrypted, access-controlled backend (the default config uses encrypted S3 with lockfiles).
- If you accidentally commit a secret, revoke it first, then remove it from history.
