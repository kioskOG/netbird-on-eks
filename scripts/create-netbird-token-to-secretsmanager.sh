#!/usr/bin/env bash
# ==============================================================================
# NetBird Out-of-Band Token Generator for AWS Secrets Manager
# ==============================================================================
# Provisions Personal Access Tokens (PATs) directly from the NetBird Management
# API into AWS Secrets Manager.
#
# GUARANTEE: Zero secrets are stored in Terraform/Terragrunt state files.
# ==============================================================================

set -euo pipefail

# Default values
NB_URL="${NB_MANAGEMENT_URL:-}"
ADMIN_PAT="${NB_PAT:-}"
REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-us-east-2}}"
EXPIRES_IN=90
USER_ID=""
TOKEN_NAME=""
SECRET_NAME=""

usage() {
  local exit_code="${1:-1}"
  cat <<EOF
Usage: $0 --user-id <ID> --name <TOKEN_NAME> [options]

Required Arguments:
  -u, --user-id       NetBird User ID to attach token to
  -n, --name          Descriptive name for the token (e.g. cicd-pipeline-token)

Optional Arguments:
  -s, --secret-name   AWS Secrets Manager secret name (default: netbird/tokens/<name>)
  -e, --expires-in    Expiration time in days (default: 90)
  -r, --region        AWS Region (default: us-east-2 or \$AWS_REGION)
  -m, --url           NetBird Management URL (default: \$NB_MANAGEMENT_URL)
  -t, --token         Admin PAT for NetBird API (default: \$NB_PAT)
  -h, --help          Show this help message

Environment Variables:
  NB_MANAGEMENT_URL   NetBird management server base URL
  NB_PAT              Admin personal access token
  AWS_PROFILE         Active AWS profile with SecretsManager permissions

Example:
  $0 --user-id "ea874e78-a7bd-4b8b-96f4-6829f06ee1a7" \\
     --name "cicd-pipeline-token" \\
     --secret-name "netbird/dev/cicd-pat"
EOF
  exit "$exit_code"
}

# Parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    -u|--user-id) USER_ID="$2"; shift 2 ;;
    -n|--name) TOKEN_NAME="$2"; shift 2 ;;
    -s|--secret-name) SECRET_NAME="$2"; shift 2 ;;
    -e|--expires-in) EXPIRES_IN="$2"; shift 2 ;;
    -r|--region) REGION="$2"; shift 2 ;;
    -m|--url) NB_URL="$2"; shift 2 ;;
    -t|--token) ADMIN_PAT="$2"; shift 2 ;;
    -h|--help) usage 0 ;;
    *) echo "Error: Unknown argument $1" >&2; usage ;;
  esac
done

# Validation
if [[ -z "$USER_ID" ]]; then
  echo "Error: Missing required argument --user-id" >&2
  usage
fi

if [[ -z "$TOKEN_NAME" ]]; then
  echo "Error: Missing required argument --name" >&2
  usage
fi

if [[ -z "$ADMIN_PAT" ]]; then
  echo "Error: NB_PAT environment variable or --token is required." >&2
  exit 1
fi

if [[ -z "$NB_URL" ]]; then
  echo "Error: NB_MANAGEMENT_URL environment variable or --url is required (e.g. https://netbird.example.com)." >&2
  exit 1
fi

if [[ -z "$SECRET_NAME" ]]; then
  SECRET_NAME="netbird/tokens/${TOKEN_NAME}"
fi

# Clean trailing slashes
NB_URL="${NB_URL%/}"

echo "============================================================"
echo " NetBird Out-of-Band Token Provisioner"
echo "============================================================"
echo "  Target Server  : ${NB_URL}"
echo "  User ID        : ${USER_ID}"
echo "  Token Name     : ${TOKEN_NAME}"
echo "  Expiration     : ${EXPIRES_IN} days"
echo "  AWS Region     : ${REGION}"
echo "  AWS Secret     : ${SECRET_NAME}"
echo "============================================================"

# Step 1: Call NetBird Management API
echo "==> Requesting token from NetBird Management API..."
API_RESPONSE=$(curl -s -f -X POST \
  -H "Authorization: Token ${ADMIN_PAT}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "{\"name\": \"${TOKEN_NAME}\", \"expires_in\": ${EXPIRES_IN}}" \
  "${NB_URL}/api/users/${USER_ID}/tokens")

TOKEN_ID=$(echo "${API_RESPONSE}" | jq -r '.personal_access_token.id // .id')
PLAIN_TOKEN=$(echo "${API_RESPONSE}" | jq -r '.plain_token // .token')

if [[ -z "$PLAIN_TOKEN" || "$PLAIN_TOKEN" == "null" ]]; then
  echo "Error: Failed to retrieve token from NetBird API. Response:" >&2
  echo "${API_RESPONSE}" >&2
  exit 1
fi

echo "  ✓ Token generated successfully: ID=${TOKEN_ID}"

# Step 2: Prepare JSON payload for AWS Secrets Manager
SECRET_PAYLOAD=$(jq -n \
  --arg pat "$PLAIN_TOKEN" \
  --arg id "$TOKEN_ID" \
  --arg user "$USER_ID" \
  --arg name "$TOKEN_NAME" \
  --arg url "$NB_URL" \
  '{
    NB_PAT: $pat,
    TOKEN_ID: $id,
    USER_ID: $user,
    TOKEN_NAME: $name,
    MANAGEMENT_URL: $url
  }')

# Step 3: Publish directly to AWS Secrets Manager
echo "==> Publishing secret to AWS Secrets Manager (${SECRET_NAME})..."

if aws secretsmanager describe-secret --secret-id "${SECRET_NAME}" --region "${REGION}" >/dev/null 2>&1; then
  IS_DELETED=$(aws secretsmanager describe-secret --secret-id "${SECRET_NAME}" --region "${REGION}" --query "DeletedDate" --output text 2>/dev/null || echo "None")
  if [[ "$IS_DELETED" != "None" && "$IS_DELETED" != "null" && -n "$IS_DELETED" ]]; then
    echo "  ℹ Secret '${SECRET_NAME}' was scheduled for deletion. Restoring..."
    aws secretsmanager restore-secret --secret-id "${SECRET_NAME}" --region "${REGION}" >/dev/null
  fi
  echo "  ℹ Updating version for secret '${SECRET_NAME}'..."
  aws secretsmanager put-secret-value \
    --secret-id "${SECRET_NAME}" \
    --secret-string "${SECRET_PAYLOAD}" \
    --region "${REGION}" >/dev/null
  echo "  ✓ Secret version updated successfully."
else
  echo "  ℹ Creating new secret '${SECRET_NAME}'..."
  aws secretsmanager create-secret \
    --name "${SECRET_NAME}" \
    --description "NetBird Personal Access Token for ${TOKEN_NAME} (${USER_ID})" \
    --secret-string "${SECRET_PAYLOAD}" \
    --region "${REGION}" \
    --tags "Key=ManagedBy,Value=Out-Of-Band-Script" "Key=Component,Value=netbird-overlay" >/dev/null
  echo "  ✓ Secret created successfully."
fi

SECRET_ARN=$(aws secretsmanager describe-secret --secret-id "${SECRET_NAME}" --region "${REGION}" --query "ARN" --output text)

echo "============================================================"
echo " SUCCESS: Token Provisioned Securely"
echo "============================================================"
echo "  Secret ARN : ${SECRET_ARN}"
echo "  State File : ZERO secrets stored in Terraform state"
echo "  Kubernetes : Ready for External Secrets Operator sync"
echo "============================================================"
