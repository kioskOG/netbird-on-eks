#!/usr/bin/env sh
# Pre-flight check run by root.hcl before plan/apply/destroy/import/refresh.
#
# Why: NetBird returns HTTP 404 for an invalid or revoked PAT. The provider reads that 404
# as "resource deleted", so a bad token yields a plan that recreates every resource
# (and can crash account-settings). Fail fast with a clear message instead.
#
# Usage: check-netbird-auth.sh <management_url>
# Skip:  NB_SKIP_AUTH_CHECK=true (e.g. offline validation with mocked dependencies)
set -eu

url="${1:?usage: check-netbird-auth.sh <management_url>}"

if [ "${NB_SKIP_AUTH_CHECK:-false}" = "true" ]; then
  exit 0
fi

if [ -z "${NB_PAT:-}" ]; then
  echo "ERROR: NB_PAT is not set. Export a NetBird admin Personal Access Token first." >&2
  exit 1
fi

code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 15 \
  -H "Authorization: Token ${NB_PAT}" \
  -H "Accept: application/json" \
  "${url%/}/api/accounts") || {
  echo "ERROR: cannot reach NetBird management API at ${url}." >&2
  exit 1
}

if [ "$code" != "200" ]; then
  echo "ERROR: NetBird API at ${url} rejected NB_PAT (HTTP ${code})." >&2
  echo "       The token is invalid, expired, revoked, or lacks admin rights." >&2
  echo "       Refusing to run: the provider would plan to recreate every resource." >&2
  exit 1
fi
