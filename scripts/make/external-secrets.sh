#!/usr/bin/env bash
# External Secrets Operator — operational validation script for NetBird.
# Adapted from the Wazuh ESO pattern (wazuh-setup/scripts/make/external-secrets.sh).
#
# Usage:
#   ./scripts/make/external-secrets.sh <status|wait|validate>
#
# Requires:
#   - kubectl configured for the target EKS cluster
#   - KUBECONFIG or ~/.kube/netbird
set -euo pipefail

ESO_NAMESPACE="${ESO_NAMESPACE:-external-secrets}"
ESO_RELEASE="${ESO_RELEASE:-external-secrets}"
STORE_NAME="${STORE_NAME:-aws-secretsmanager}"

bold()  { printf '\033[1m%s\033[0m\n' "$*"; }
green() { printf '\033[1;32m%s\033[0m\n' "$*"; }
red()   { printf '\033[1;31m%s\033[0m\n' "$*"; }
die()   { red "ERROR: $*" >&2; exit 1; }

require_kube() {
  command -v kubectl &>/dev/null || die "kubectl not found"
  kubectl cluster-info &>/dev/null || die "Cannot reach Kubernetes cluster"
}

action="${1:-}"

case "$action" in
  status)
    require_kube
    bold "=== External Secrets Operator ==="
    kubectl get deploy,pods -n "$ESO_NAMESPACE" 2>/dev/null || true
    echo ""
    bold "=== ClusterSecretStore ==="
    kubectl get clustersecretstore "$STORE_NAME" -o wide 2>/dev/null || echo "(not found)"
    echo ""
    bold "=== ExternalSecrets (all namespaces) ==="
    kubectl get externalsecret -A -o wide 2>/dev/null || echo "(none)"
    ;;

  wait)
    require_kube
    bold "Waiting for ESO CRDs..."
    kubectl wait --for=condition=Established \
      crd/clustersecretstores.external-secrets.io --timeout=120s
    kubectl wait --for=condition=Established \
      crd/externalsecrets.external-secrets.io --timeout=120s
    bold "Waiting for ESO deployment..."
    kubectl rollout status "deployment/${ESO_RELEASE}" \
      -n "$ESO_NAMESPACE" --timeout=180s
    kubectl rollout status "deployment/${ESO_RELEASE}-webhook" \
      -n "$ESO_NAMESPACE" --timeout=180s
    bold "Waiting for ClusterSecretStore..."
    kubectl wait --for=condition=Ready \
      "clustersecretstore/${STORE_NAME}" --timeout=120s
    green "ESO is fully ready"
    ;;

  validate)
    require_kube
    PASS=0
    FAIL=0

    check() {
      local label="$1"; shift
      if "$@" &>/dev/null; then
        green "  PASS  $label"
        PASS=$((PASS + 1))
      else
        red   "  FAIL  $label"
        FAIL=$((FAIL + 1))
      fi
    }

    bold "=== ESO Validation ==="
    check "ESO deployment ready" \
      kubectl rollout status "deployment/${ESO_RELEASE}" -n "$ESO_NAMESPACE" --timeout=10s
    check "ESO webhook ready" \
      kubectl rollout status "deployment/${ESO_RELEASE}-webhook" -n "$ESO_NAMESPACE" --timeout=10s
    check "ExternalSecret CRD" \
      kubectl get crd externalsecrets.external-secrets.io
    check "ClusterSecretStore CRD" \
      kubectl get crd clustersecretstores.external-secrets.io
    check "ClusterSecretStore ready" \
      kubectl wait --for=condition=Ready "clustersecretstore/${STORE_NAME}" --timeout=10s
    check "ServiceAccount exists" \
      kubectl get sa "$ESO_RELEASE" -n "$ESO_NAMESPACE"
    check "IRSA annotation present" \
      kubectl get sa "$ESO_RELEASE" -n "$ESO_NAMESPACE" -o jsonpath='{.metadata.annotations.eks\.amazonaws\.com/role-arn}'

    # Check logs for auth errors
    if kubectl logs "deployment/${ESO_RELEASE}" -n "$ESO_NAMESPACE" --tail=100 2>/dev/null \
       | grep -qiE 'AccessDenied|InvalidClientTokenId|NoCredentialProviders'; then
      red   "  FAIL  No auth errors in logs"
      FAIL=$((FAIL + 1))
    else
      green "  PASS  No auth errors in logs"
      PASS=$((PASS + 1))
    fi

    echo ""
    bold "Results: ${PASS} passed, ${FAIL} failed"
    [[ $FAIL -eq 0 ]] && green "ESO VALIDATION: PASS" || red "ESO VALIDATION: FAIL"
    exit $FAIL
    ;;

  *)
    die "Usage: $0 <status|wait|validate>"
    ;;
esac
