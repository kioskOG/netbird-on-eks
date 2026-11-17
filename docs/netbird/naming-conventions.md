# NetBird Resource Naming Conventions

To maintain organization and clarity across the self-hosted platform, all NetBird resources MUST adhere to the following standard naming patterns.

| Resource Type | Naming Pattern | Examples |
|---|---|---|
| **Peers** | `peer-<team>-<env>` | `peer-devops-prod`, `peer-support-prod` |
| **Services (Groups)** | `svc-<app>-<tier>-<env>` | `svc-orders-web-prod`, `svc-orders-db-prod` |
| **Networks** | `net-<provider>-<region>-<env>` | `net-aws-euc1-prod`, `net-dc-dc1-lan` |
| **Policies** | `<source> -> <dest> [<protocol>/<port>]` | `peer-devops-prod -> svc-orders-web-prod [TCP/443]` |
| **Setup Keys** | `setup-<env>-<purpose>` | `setup-prod-servers` |

## Application Notes
- **Peers**: Reflect the human or systemic owner (team) and the environment.
- **Services**: Used for grouping endpoints that serve a specific application tier.
- **Policies**: The naming explicitly reflects the intent and scope of the rule, making audits significantly easier.
- **Setup Keys**: Clearly identify the target environment and use case for the enrolled peers.
