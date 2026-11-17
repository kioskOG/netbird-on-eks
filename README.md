# NetBird on EKS

> **Before you deploy:** every environment-specific value is a `REPLACE_ME_<NAME>` placeholder. Run `scripts/placeholders.py init`, fill in the generated `*.local` files, and see [PLACEHOLDERS.md](PLACEHOLDERS.md) for what each value means.

This repository deploys a self-hosted [NetBird](https://netbird.io) control plane on Amazon EKS. One combined server pod runs management, signal, relay, and STUN. A second pod serves the dashboard. Postgres is CloudNativePG. Secrets come from AWS Secrets Manager through External Secrets. Public HTTPS is one Application Load Balancer. STUN is a separate Network Load Balancer on UDP 3478.

The environment that matches the files under `services/infra/core/*/dev` is:

| Item | Value |
|---|---|
| AWS profile | `REPLACE_ME_AWS_PROFILE` |
| Account | `REPLACE_ME_AWS_ACCOUNT_ID` |
| Region | `us-east-2` |
| EKS cluster | `netbird` |
| Cluster VPC | `REPLACE_ME_VPC_ID` |
| Public name | `netbird.REPLACE_ME_DOMAIN` |
| DNS | GoDaddy for `REPLACE_ME_DOMAIN` |

`services/infra/core/netbird/prod` is a second copy of the NetBird chart. It does not have the identity-provider sync or the HTTP/2 gRPC target group used by dev. Deploy dev unless you have updated prod to match.

### Adapting it to your environment

The values in the table are the reference environment. In the repository every
environment-specific value (AWS account ID, region, VPC ID, domain, ACM certificate, IAM roles,
Keycloak credentials) is a `REPLACE_ME_<NAME>` placeholder. Do not edit the committed files: put
your real values in gitignored `*.local` overrides that Helm and Terragrunt layer on top.

```sh
scripts/placeholders.py init    # creates every *.local.yaml / .envrc.local with the keys to fill
$EDITOR <files it lists>        # replace each REPLACE_ME_* with your value
scripts/placeholders.py check   # exits non-zero until every placeholder has a value
```

[PLACEHOLDERS.md](PLACEHOLDERS.md) lists what each placeholder means, every file and line that
uses it, and the exact override file to create. Helm installs below pass `-f values.local.yaml`;
Terragrunt merges `<name>.local.yaml` automatically. Supply secrets only at runtime (`NB_PAT`);
see [CONTRIBUTING.md](CONTRIBUTING.md) for the toolchain and checks.

## What you are building

```text
Browser / NetBird client
        |
        |  HTTPS 443
        v
   one internet-facing ALB          NLB  UDP 3478 (STUN only, no certificate)
        |
        +-- /                 dashboard
        +-- /api /oauth2      NetBird server
        +-- /relay /ws-proxy  NetBird server
        +-- gRPC paths        NetBird server (HTTP/2 target group)
                |
                +-- Postgres (CloudNativePG, database netbird)
                +-- PVC for the embedded identity provider (idp.db)
```

Users log in to NetBird. NetBird's own issuer stays `https://<domain>/oauth2`. Google, Keycloak, Entra, and the other providers in the dashboard list are login buttons behind that issuer. Do not point `oidc.authority` at Keycloak, and do not put an ALB authenticate-oidc rule in front of the Ingress. Clients, gRPC, the relay, and `/oauth2` call NetBird directly.

## Tools

- AWS CLI, profile `REPLACE_ME_AWS_PROFILE`, region `us-east-2`
- `kubectl`, `helm` 3
- `openssl`, `jq`
- Access to the DNS host for the public name (GoDaddy in this setup)

```bash
aws sts get-caller-identity --profile REPLACE_ME_AWS_PROFILE
aws eks update-kubeconfig --name netbird --region us-east-2 --profile REPLACE_ME_AWS_PROFILE
kubectl config current-context
```

The context should be the `netbird` cluster in `us-east-2`.

## Before any Helm install

The cluster, its VPC, and the IAM roles below are assumed to exist. This repo does not create the EKS cluster.

Confirm the cluster VPC, then list its subnets. Public subnets in at least two availability zones need a route to an internet gateway and the tag `kubernetes.io/role/elb=1`. Keep any existing `kubernetes.io/cluster/netbird` tag. Do not put the ELB tag on private subnets. Private subnets used for internal load balancers need `kubernetes.io/role/internal-elb=1` instead.

```bash
aws eks describe-cluster \
  --profile REPLACE_ME_AWS_PROFILE --region us-east-2 --name netbird \
  --query 'cluster.resourcesVpcConfig.vpcId' --output text

aws ec2 describe-subnets \
  --profile REPLACE_ME_AWS_PROFILE --region us-east-2 \
  --filters Name=vpc-id,Values=REPLACE_ME_VPC_ID \
  --query 'Subnets[].{Id:SubnetId,AZ:AvailabilityZone,Public:MapPublicIpOnLaunch,Name:Tags[?Key==`Name`].Value|[0]}' \
  --output table

aws ec2 create-tags \
  --profile REPLACE_ME_AWS_PROFILE --region us-east-2 \
  --resources subnet-PUBLIC-A subnet-PUBLIC-B \
  --tags Key=kubernetes.io/role/elb,Value=1
```

Replace `subnet-PUBLIC-A` and `subnet-PUBLIC-B` with the public subnet ids from the table. `MapPublicIpOnLaunch` true means the subnet is public.

Confirm the two IAM roles used by the charts:

```bash
aws iam get-role --profile REPLACE_ME_AWS_PROFILE \
  --role-name AWSLoadBalancerControllerRole \
  --query 'Role.Arn' --output text

aws iam get-role --profile REPLACE_ME_AWS_PROFILE \
  --role-name ESOControllerServiceAccountRole \
  --query 'Role.Arn' --output text
```

Expected ARNs:

- `arn:aws:iam::REPLACE_ME_AWS_ACCOUNT_ID:role/AWSLoadBalancerControllerRole`
- `arn:aws:iam::REPLACE_ME_AWS_ACCOUNT_ID:role/ESOControllerServiceAccountRole`

The External Secrets role must be allowed to read `dev/netbird/keys` and `dev/netbird/postgresql`.

If the controller is installed with the wrong VPC id, it will not create load balancers. The value that must match the cluster is `vpcId` in `services/infra/core/aws-alb-controller/dev/values.yaml`. After the controller is installed, check the argument:

```bash
kubectl -n kube-system get deploy \
  -l app.kubernetes.io/name=aws-load-balancer-controller \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{.spec.template.spec.containers[0].args}{"\n"}{end}'
```

The args must include `--aws-vpc-id=REPLACE_ME_VPC_ID`.

## 1. Create the secrets

Do this before Helm. External Secrets will not become Ready until these JSON secrets exist, and a failed sync of `dev/netbird/keys` takes the NetBird server down with it.

Generate the JSON files in a directory outside the git checkout. Do not commit them. `idp-client-secret` and `idp-admin-token` are added in section 8, after the first user exists. Leave them out of this first secret.

```bash
mkdir -p "$HOME/netbird-bootstrap"
cd "$HOME/netbird-bootstrap"

jq -n \
  --arg auth "$(openssl rand -base64 32)" \
  --arg data "$(openssl rand -base64 32)" \
  --arg session "$(openssl rand -base64 32)" \
  '{
    "auth-secret": $auth,
    "datastore-encryption-key": $data,
    "session-cookie-encryption-key": $session
  }' > keys.json

jq -n \
  --arg password "$(openssl rand -base64 32)" \
  '{"username": "netbird", "password": $password}' > pg.json

aws secretsmanager create-secret \
  --profile REPLACE_ME_AWS_PROFILE --region us-east-2 \
  --name dev/netbird/keys \
  --secret-string file://keys.json

aws secretsmanager create-secret \
  --profile REPLACE_ME_AWS_PROFILE --region us-east-2 \
  --name dev/netbird/postgresql \
  --secret-string file://pg.json

rm -f keys.json pg.json
```

If a secret already exists, `create-secret` fails. Update it instead:

```bash
aws secretsmanager put-secret-value \
  --profile REPLACE_ME_AWS_PROFILE --region us-east-2 \
  --secret-id dev/netbird/keys \
  --secret-string file://keys.json

aws secretsmanager put-secret-value \
  --profile REPLACE_ME_AWS_PROFILE --region us-east-2 \
  --secret-id dev/netbird/postgresql \
  --secret-string file://pg.json
```

Confirm the names, not the values:

```bash
aws secretsmanager describe-secret \
  --profile REPLACE_ME_AWS_PROFILE --region us-east-2 \
  --secret-id dev/netbird/keys \
  --query '{Name:Name,ARN:ARN}'

aws secretsmanager describe-secret \
  --profile REPLACE_ME_AWS_PROFILE --region us-east-2 \
  --secret-id dev/netbird/postgresql \
  --query '{Name:Name,ARN:ARN}'
```

After `put-secret-value` on a cluster that is already running, External Secrets waits for its refresh interval (`1h` in the NetBird values) unless you force a sync. Only `netbird-keys` exists at this stage. `netbird-idp` is created in section 8, when `idp.enabled` is true. Annotating it before that returns `NotFound`.

```bash
kubectl -n netbird annotate externalsecret netbird-keys force-sync="$(date +%s)" --overwrite
kubectl -n netbird get externalsecret
```

## 2. Edit the dev values

Change these before the first install if this is not the `REPLACE_ME_DOMAIN` environment. Leave everything else.

| File | Fields | What to set |
|---|---|---|
| `services/infra/core/aws-alb-controller/dev/values.yaml` | `vpcId`, `region`, `clusterName`, `serviceAccount.annotations` | Cluster VPC, region, cluster name, controller IAM role ARN |
| `services/infra/core/external-secrets/dev/values.yaml` | `aws.region`, `serviceAccount.annotations` | Region and External Secrets IAM role ARN |
| `services/infra/core/netbird/dev/values.yaml` | `global.domain`, `global.protocol`, `global.publicPort` | Public HTTPS name. Protocol `https`, port `443` |
| same file | `secrets.awsSecretName`, `secrets.clusterSecretStoreName` | Secrets Manager name and the ClusterSecretStore (`aws-secretsmanager`) |
| same file | `database.secretName`, `database.name` | Must stay `netbird-pg-app` and `netbird` unless you also change the CloudNativePG templates |
| same file | `ingress.certificateArn` | ACM certificate ARN in `us-east-2`. Empty until section 5 |
| same file | `idp.enabled` | `false` for the first install. Turn it on in section 8 |
| same file | `oidc.authority` | Leave empty. Empty means `https://<domain>/oauth2` |

`idp.type` accepts `oidc`, `google`, `microsoft`, `entra`, `okta`, `zitadel`, `pocketid`, `authentik`, `keycloak`, `adfs`. Google and Microsoft do not use `idp.issuer`. Any other type fails the Helm render if `issuer` is empty.

Postgres for this app is created by `services/infra/core/cloudnative-pg/dev/templates/cluster.yaml` in the `netbird` namespace: one instance, database `netbird`, owner `netbird`, password from secret `netbird-pg-app`. The app user secret is filled from `dev/netbird/postgresql` by `services/infra/core/cloudnative-pg/dev/templates/externalsecret.yaml`.

## 3. Install the platform charts

From the repository root. Each wrapper chart vendors an upstream chart, so build dependencies first.

```bash
# External Secrets
cd services/infra/core/external-secrets/dev
helm dependency update
helm upgrade --install external-secrets . \
  --namespace external-secrets \
  --create-namespace \
  -f values.yaml -f values.local.yaml \
  --wait

# AWS Load Balancer Controller
cd ../../aws-alb-controller/dev
helm dependency update
helm upgrade --install aws-load-balancer-controller . \
  --namespace kube-system \
  -f values.yaml -f values.local.yaml \
  --wait

# CloudNativePG operator, then the NetBird database
cd ../../cloudnative-pg/dev
helm dependency update
kubectl create namespace netbird --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install cnpg . \
  --namespace cnpg-system \
  --create-namespace \
  -f values.yaml \
  --wait
```

Confirm before continuing:

```bash
kubectl -n external-secrets get pods
kubectl -n kube-system get pods -l app.kubernetes.io/name=aws-load-balancer-controller
kubectl -n netbird get cluster,secret
kubectl -n netbird get externalsecret netbird-pg-credentials
```

`netbird-postgresql` should be healthy, and secret `netbird-pg-app` should exist.

```bash
kubectl -n netbird get cluster netbird-postgresql
kubectl -n netbird get secret netbird-pg-app
kubectl -n kube-system logs \
  -l app.kubernetes.io/name=aws-load-balancer-controller --tail=80
```

The controller logs should show VPC `REPLACE_ME_VPC_ID` and should not say `unable to resolve at least one subnet`.

The controller chart dependency is `aws-load-balancer-controller` 3.6.0 (controller v3.6.0). The wrapper chart also carries the Gateway API v1.6.3 standard CRDs in `crds/`, and the subchart carries the `gateway.k8s.aws` CRDs. Helm installs both before the controller starts, so Gateway API support is on from the first install. The controller's IAM policy is `terragrunt/infrastructure-live/accounts/mlops/global/iam/role/policy/AWSLoadBalancerController.json`, which is the upstream v3.6.0 `iam_policy.json`. Apply that IAM change before installing this chart.

Helm installs files in `crds/` only once. It never upgrades or deletes them. To move to a newer Gateway API release later, apply its CRDs yourself:

```bash
kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/<version>/standard-install.yaml
```

The gRPC paths use an HTTP/2 target group with an HTTP `200` health check (`ingress.grpcAnnotations` in the NetBird values). Controller v2.6 rejected `GRPC` with that matcher. The HTTP/2 setup still works on v3.6 and is unchanged.

Check that the CRDs are present:

```bash
kubectl get crd | grep -E 'gateway.networking.k8s.io|gateway.k8s.aws'
```

## 4. Install NetBird with local login only

In `services/infra/core/netbird/dev/values.yaml` set `idp.enabled: false`. `ingress.certificateArn` can still be empty for this step. The pods will run. The ALB will not be created until a certificate ARN is set, because the Ingress asks for HTTPS.

```bash
cd services/infra/core/netbird/dev
helm upgrade --install netbird . \
  --namespace netbird \
  -f values.yaml -f values.local.yaml \
  --wait
```

```bash
kubectl -n netbird get pods
kubectl -n netbird get externalsecret netbird-keys
kubectl -n netbird get ingress
```

Expect `netbird-server`, `netbird-dashboard`, and `netbird-postgresql` at `1/1`, and `netbird-keys` `SecretSynced`. The Ingress address stays empty until section 5.

## 5. Certificate

The ALB and the certificate must be in the same region (`us-east-2`).

Import a certificate you already have, or request one from ACM. The name on the certificate must include `netbird.REPLACE_ME_DOMAIN`. A certificate that is only `*.REPLACE_ME_DOMAIN` covers that name. `netbird.REPLACE_ME_DOMAIN.cert` in this repo is the leaf plus the Let's Encrypt chain. `netbird.REPLACE_ME_DOMAIN.key` is the private key. `*.key` is gitignored. Do not commit the key.

Split the bundle, then import. `cert-1.pem` is the leaf. The following files are the chain. In the ACM console, **Certificate body** takes only that leaf. Paste the other two blocks, in order, into **Certificate chain**. Importing the leaf alone makes the dashboard load in a browser and makes `netbird up` fail. See [Troubleshooting](#troubleshooting).

```bash
cd /path/to/Netbird-setup

awk '
  /-----BEGIN CERTIFICATE-----/ {n++; f=sprintf("cert-%d.pem", n)}
  f {print > f}
  /-----END CERTIFICATE-----/ {close(f); f=""}
' netbird.REPLACE_ME_DOMAIN.cert

cat cert-2.pem cert-3.pem > chain.pem

aws acm import-certificate \
  --profile REPLACE_ME_AWS_PROFILE \
  --region us-east-2 \
  --certificate fileb://cert-1.pem \
  --certificate-chain fileb://chain.pem \
  --private-key fileb://netbird.REPLACE_ME_DOMAIN.key

rm -f cert-1.pem cert-2.pem cert-3.pem chain.pem
```

The import command prints `CertificateArn`. Confirm it:

```bash
aws acm list-certificates \
  --profile REPLACE_ME_AWS_PROFILE --region us-east-2 \
  --query 'CertificateSummaryList[?DomainName==`netbird.REPLACE_ME_DOMAIN`].{Arn:CertificateArn,Status:Status}' \
  --output table

aws acm describe-certificate \
  --profile REPLACE_ME_AWS_PROFILE --region us-east-2 \
  --certificate-arn arn:aws:acm:us-east-2:REPLACE_ME_AWS_ACCOUNT_ID:certificate/CERT_ID \
  --query 'Certificate.{Status:Status,Domain:DomainName,NotAfter:NotAfter}'
```

To request a new certificate instead of importing:

```bash
aws acm request-certificate \
  --profile REPLACE_ME_AWS_PROFILE \
  --region us-east-2 \
  --domain-name netbird.REPLACE_ME_DOMAIN \
  --validation-method DNS

aws acm describe-certificate \
  --profile REPLACE_ME_AWS_PROFILE --region us-east-2 \
  --certificate-arn arn:aws:acm:us-east-2:REPLACE_ME_AWS_ACCOUNT_ID:certificate/CERT_ID \
  --query 'Certificate.DomainValidationOptions[].ResourceRecord'
```

Create the CNAME from that output in GoDaddy, then wait until the status is `ISSUED`:

```bash
aws acm wait certificate-validated \
  --profile REPLACE_ME_AWS_PROFILE --region us-east-2 \
  --certificate-arn arn:aws:acm:us-east-2:REPLACE_ME_AWS_ACCOUNT_ID:certificate/CERT_ID
```

ACM does not renew an imported certificate. Re-import before it expires and pass the same `--certificate-arn` so the ARN does not change. The current imported certificate expires on 25 December 2026.

```bash
aws acm import-certificate \
  --profile REPLACE_ME_AWS_PROFILE \
  --region us-east-2 \
  --certificate-arn arn:aws:acm:us-east-2:REPLACE_ME_AWS_ACCOUNT_ID:certificate/CERT_ID \
  --certificate fileb://cert-1.pem \
  --certificate-chain fileb://chain.pem \
  --private-key fileb://netbird.REPLACE_ME_DOMAIN.key
```

Put the ARN in `ingress.certificateArn` in `services/infra/core/netbird/dev/values.yaml`, then upgrade from that chart directory:

```bash
cd services/infra/core/netbird/dev
helm upgrade netbird . --namespace netbird -f values.yaml -f values.local.yaml --timeout 8m
kubectl -n netbird get ingress -o wide
kubectl -n netbird describe ingress
```

All three Ingresses (`netbird-http`, `netbird-grpc`, `netbird-dashboard`) must show the same hostname. That is one ALB, group name `netbird`. If the address stays empty, describe the Ingress. The two failures already hit by this install were "no certificate found for host" (ARN missing) and "Health check matcher GRPC code 200" (gRPC protocol version on the old controller v2.6).

There should be one application load balancer and one network load balancer:

```bash
aws elbv2 describe-load-balancers --profile REPLACE_ME_AWS_PROFILE --region us-east-2 \
  --query 'LoadBalancers[].{Name:LoadBalancerName,Type:Type,DNS:DNSName}'
```

The NLB listener is UDP 3478 only. It does not use a certificate.

```bash
ALB_ARN=$(aws elbv2 describe-load-balancers \
  --profile REPLACE_ME_AWS_PROFILE --region us-east-2 \
  --query 'LoadBalancers[?Type==`application`].LoadBalancerArn' --output text)

aws elbv2 describe-listeners \
  --profile REPLACE_ME_AWS_PROFILE --region us-east-2 \
  --load-balancer-arn "$ALB_ARN" \
  --query 'Listeners[].{Port:Port,Protocol:Protocol}'

aws elbv2 describe-target-health \
  --profile REPLACE_ME_AWS_PROFILE --region us-east-2 \
  --target-group-arn "$(aws elbv2 describe-target-groups \
    --profile REPLACE_ME_AWS_PROFILE --region us-east-2 \
    --load-balancer-arn "$ALB_ARN" \
    --query 'TargetGroups[0].TargetGroupArn' --output text)"
```

Run `describe-target-health` once per target group ARN from:

```bash
aws elbv2 describe-target-groups \
  --profile REPLACE_ME_AWS_PROFILE --region us-east-2 \
  --load-balancer-arn "$ALB_ARN" \
  --query 'TargetGroups[].{Name:TargetGroupName,Port:Port,Path:HealthCheckPath,HealthPort:HealthCheckPort,Arn:TargetGroupArn}' \
  --output table
```

## 6. DNS

Read the ALB hostname, then in GoDaddy create a CNAME from `netbird` to that hostname (`*.us-east-2.elb.amazonaws.com`). No ACM validation CNAME is required for an imported certificate.

```bash
kubectl -n netbird get ingress \
  -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}{"\n"}'
```

Wait until both of these work:

```bash
curl -fsS -o /dev/null -w "%{http_code}\n" https://netbird.REPLACE_ME_DOMAIN/
curl -fsS -o /dev/null -w "%{http_code}\n" https://netbird.REPLACE_ME_DOMAIN/oauth2/.well-known/openid-configuration
```

Both should be `200`.

## 7. First admin

Open `https://netbird.REPLACE_ME_DOMAIN/` and create the first user. That account is the owner. Password login stays available (`localAuthDisabled` is false in the server config).

In the dashboard, create a personal access token for that user (Settings, or the user menu, Personal Access Tokens). You need it for section 8. It is shown once. The token in this environment is named `idp-sync` and expires 365 days after it was created.

Store it without dropping the keys that are already in the secret. `IDP_ADMIN_TOKEN` is the value from the dashboard. This command does not print the secret.

```bash
export IDP_CLIENT_SECRET='paste-the-client-secret-here'

aws secretsmanager get-secret-value \
  --profile REPLACE_ME_AWS_PROFILE --region us-east-2 \
  --secret-id dev/netbird/keys \
  --query SecretString --output text \
| jq --arg token "$IDP_ADMIN_TOKEN" '. + {"idp-admin-token": $token}' \
  > "$HOME/netbird-keys.json"

aws secretsmanager put-secret-value \
  --profile REPLACE_ME_AWS_PROFILE --region us-east-2 \
  --secret-id dev/netbird/keys \
  --secret-string "file://$HOME/netbird-keys.json"

rm -f "$HOME/netbird-keys.json"
unset IDP_ADMIN_TOKEN
```

When the token expires, create a new one in the dashboard and run those commands again, then:

```bash
kubectl -n netbird annotate externalsecret netbird-idp force-sync="$(date +%s)" --overwrite
cd services/infra/core/netbird/dev
helm upgrade netbird . --namespace netbird -f values.yaml -f values.local.yaml --timeout 8m
```

## 8. Turn on an identity provider

Keep `oidc.authority` empty.

1. At the provider, create a confidential OpenID Connect client with the standard authorization-code flow.
2. Client id goes in `idp.clientId`. Client secret goes in Secrets Manager as `idp-client-secret` on `dev/netbird/keys`. Do not put the secret in `values.yaml`.

```bash
export IDP_CLIENT_SECRET='paste-the-client-secret-here'

aws secretsmanager get-secret-value \
  --profile REPLACE_ME_AWS_PROFILE --region us-east-2 \
  --secret-id dev/netbird/keys \
  --query SecretString --output text \
| jq --arg secret "$IDP_CLIENT_SECRET" '. + {"idp-client-secret": $secret}' \
  > "$HOME/netbird-keys.json"

aws secretsmanager put-secret-value \
  --profile REPLACE_ME_AWS_PROFILE --region us-east-2 \
  --secret-id dev/netbird/keys \
  --secret-string "file://$HOME/netbird-keys.json"

rm -f "$HOME/netbird-keys.json"
unset IDP_CLIENT_SECRET
```

Do not annotate `netbird-idp` yet. That ExternalSecret does not exist until the Helm upgrade below. On that first upgrade it reads `idp-client-secret` and `idp-admin-token` from Secrets Manager by itself. Use the annotate command only when those JSON keys change later, after `netbird-idp` is already in the namespace.
3. Set `idp.enabled: true`, `idp.type`, `idp.name`, and `idp.issuer`.

   For Google or Microsoft, delete or leave `idp.issuer` empty. NetBird fills in the built-in issuer.

   For Keycloak, Entra, Okta, Zitadel, Authentik, Pocket ID, AD FS, or generic OIDC, `idp.issuer` is required and must be the HTTPS issuer URL, for example `https://keycloak.REPLACE_ME_DOMAIN/realms/netbird`.

4. On the provider, allow redirect `https://netbird.REPLACE_ME_DOMAIN/oauth2/callback/*` and post-logout `https://netbird.REPLACE_ME_DOMAIN/oauth2/logout/callback`. The wildcard is there because NetBird generates the connector id (`keycloak-<id>`, `google-<id>`, and so on). After the upgrade, the job log prints the exact callback. Put that exact URI on the client as well if the provider does not accept a wildcard.

5. Upgrade:

```bash
cd services/infra/core/netbird/dev
helm upgrade netbird . --namespace netbird -f values.yaml -f values.local.yaml --timeout 8m
kubectl -n netbird logs -l app.kubernetes.io/component=idp-sync --tail=20
```

A successful log looks like:

```text
created keycloak-<id>
redirect https://netbird.REPLACE_ME_DOMAIN/oauth2/callback/keycloak-<id>
```

The job updates an existing provider when `idp.name` is unchanged, and creates a new one when the name is new. A failed job fails the Helm release. Read that log before running the upgrade again.

Log out. The login page shows a button with `idp.name`. The local owner can still sign in with a password.

Keycloak, as configured for this environment:

| NetBird value | Keycloak |
|---|---|
| `idp.type` | `keycloak` |
| `idp.clientId` | client id `netbird` in realm `netbird` |
| `idp.issuer` | `https://keycloak.REPLACE_ME_DOMAIN/realms/netbird` |
| `idp-client-secret` | client secret from the Keycloak Credentials tab |

The issuer must be reachable from the NetBird server pod. The create call checks `https://<issuer>/.well-known/openid-configuration` and requires the returned `issuer` to match.

```bash
kubectl -n netbird run issuer-check --restart=Never --rm -i \
  --image=curlimages/curl:8.10.1 -- \
  curl -fsS https://keycloak.REPLACE_ME_DOMAIN/realms/netbird/.well-known/openid-configuration
```

Replace the URL with `idp.issuer` plus `/.well-known/openid-configuration`. The JSON field `issuer` must equal `idp.issuer`.

## 9. STUN

```bash
kubectl -n netbird get svc netbird-stun -o wide

NLB_ARN=$(aws elbv2 describe-load-balancers \
  --profile REPLACE_ME_AWS_PROFILE --region us-east-2 \
  --query 'LoadBalancers[?Type==`network`].LoadBalancerArn' --output text)

aws elbv2 describe-listeners \
  --profile REPLACE_ME_AWS_PROFILE --region us-east-2 \
  --load-balancer-arn "$NLB_ARN" \
  --query 'Listeners[].{Port:Port,Protocol:Protocol,Certificates:Certificates}'
```

The service should show an external hostname. That hostname is the NLB. The listener is UDP 3478 and `Certificates` is null. Peers are told to use `stun:<global.domain>:3478`. The public name is a CNAME to the ALB, and the ALB does not forward UDP, so NAT traversal through that name fails.

To make STUN work, give the NLB its own DNS name and teach clients that name. This chart does not yet set a separate STUN host; it only publishes `stunPorts: [3478]` from `global.domain`.

## Changing the running install

| You want to | Where | Then |
|---|---|---|
| Change the public name | `global.domain`, the ACM certificate, the DNS CNAME, and the provider redirect URIs | Helm upgrade |
| Replace the certificate | `ingress.certificateArn` | Helm upgrade. Re-import onto the same ARN when the imported cert is renewed |
| Switch identity provider | `idp.type`, `idp.name`, `idp.clientId`, `idp.issuer`, and `idp-client-secret` | Helm upgrade. Google and Microsoft: clear `issuer` |
| Rotate the API token used by the sync job | `idp-admin-token` in `dev/netbird/keys` | Force-sync `netbird-idp`, then Helm upgrade |

Command, from `services/infra/core/netbird/dev`:

```bash
cd services/infra/core/netbird/dev
helm upgrade netbird . --namespace netbird -f values.yaml -f values.local.yaml --timeout 8m
kubectl -n netbird rollout status deploy/netbird-server
kubectl -n netbird rollout status deploy/netbird-dashboard
kubectl -n netbird logs -l app.kubernetes.io/component=idp-sync --tail=20
```

## Checks

```bash
kubectl -n netbird get pods,ingress,svc,externalsecret
kubectl -n netbird get ingress -o wide
curl -fsS -o /dev/null -w "dashboard %{http_code}\n" https://netbird.REPLACE_ME_DOMAIN/
curl -fsS -o /dev/null -w "oidc %{http_code}\n" https://netbird.REPLACE_ME_DOMAIN/oauth2/.well-known/openid-configuration
kubectl -n netbird logs deploy/netbird-server --tail=40
```

Target groups on the ALB should be healthy: dashboard on `/`, the HTTP API on `/metrics` port 9090, and the HTTP/2 gRPC group on `/oauth2/.well-known/openid-configuration` port 80. The metrics port is HTTP/1 only, so the HTTP/2 group cannot health-check it.

## Troubleshooting

### `netbird up` ends with `DeadlineExceeded`

```text
Error: daemon up failed: login backoff cycle failed: rpc error: code = DeadlineExceeded desc = create connection: dial context: context deadline exceeded
```

Port 443 is open. The client gives up while retrying a TLS failure. On the peer, `/var/log/netbird/client.log` contains:

```text
tls: failed to verify certificate: x509: certificate signed by unknown authority
```

The ALB is sending the leaf twice and leaving out the Let's Encrypt `YR2` intermediate. That happens when ACM was given only the first certificate in `netbird.REPLACE_ME_DOMAIN.cert`. A browser still opens the dashboard, because it downloads the missing intermediate. The NetBird client does not.

Re-import onto the certificate the load balancer already uses. Run this from the repo root. The same command fails with `No such file or directory: 'netbird.REPLACE_ME_DOMAIN.cert'` from any other directory.

```bash
cd /path/to/Netbird-setup

python3 - <<'PY'
from pathlib import Path
text = Path("netbird.REPLACE_ME_DOMAIN.cert").read_text()
parts = [p.strip() + "\n-----END CERTIFICATE-----\n" for p in text.split("-----END CERTIFICATE-----") if "BEGIN CERTIFICATE" in p]
Path("cert-1.pem").write_text(parts[0])
Path("chain.pem").write_text("".join(parts[1:]))
PY

aws acm import-certificate \
  --profile REPLACE_ME_AWS_PROFILE \
  --region us-east-2 \
  --certificate-arn arn:aws:acm:us-east-2:REPLACE_ME_AWS_ACCOUNT_ID:certificate/REPLACE_ME_ACM_CERTIFICATE_ID \
  --certificate fileb://cert-1.pem \
  --certificate-chain fileb://chain.pem \
  --private-key fileb://netbird.REPLACE_ME_DOMAIN.key

rm -f cert-1.pem chain.pem
```

`cert-1.pem` is the leaf (lines 1–35). `chain.pem` is the `YR2` intermediate and the `Root YR` cross-sign (lines 37–99). Do not put the leaf in the chain.

Confirm the chain, then enroll the peer again:

```bash
echo | openssl s_client -connect netbird.REPLACE_ME_DOMAIN:443 -servername netbird.REPLACE_ME_DOMAIN -showcerts 2>/dev/null \
  | awk '/s:|i:/'
```

The subjects should be the leaf, then `YR2`, then `Root YR`. A second copy of `netbird.REPLACE_ME_DOMAIN` means the chain is still missing.

## Do not

- Commit `*.key`, the client secret, the personal access token, or the Postgres password.
- Set `oidc.authority` to the external provider. The dashboard and the clients trust NetBird's `/oauth2` issuer.
- Add `alb.ingress.kubernetes.io/auth-type` or `authenticate-oidc`. That inserts a login page in front of `/api`, `/oauth2`, `/relay`, and gRPC.
- Set `backend-protocol-version: GRPC` together with an HTTP `200` success code. Controller v2.6 refused to create the ALB with that combination.
- Expect the NLB to terminate HTTPS. Its only listener is UDP 3478.
