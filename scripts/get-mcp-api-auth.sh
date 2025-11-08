#!/bin/bash
# Récupère l'authorization header depuis Vault pour Docker Desktop
# Usage: ./get-mcp-api-auth.sh <api-name>

set -euo pipefail

API_NAME=$1

if [ -z "$API_NAME" ]; then
  echo "❌ Usage: $0 <api-name>"
  echo ""
  echo "Examples:"
  echo "  $0 weatherapi"
  echo "  $0 openai-api"
  echo "  $0 github-api"
  echo ""
  echo "Available APIs in Vault:"
  vault kv list datligent/mcp/shared 2>/dev/null || echo "  (none)"
  exit 1
fi

export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="${VAULT_TOKEN:-$(cat /Users/adminmac/vault-datligent/init-data/vault-init.json | jq -r '.root_token')}"

# Vérifier que Vault est accessible
if ! vault status >/dev/null 2>&1; then
  echo "❌ Vault is not accessible"
  echo "   Run: ./scripts/vault-health-check.sh"
  exit 1
fi

# Récupérer le secret
SECRET=$(vault kv get -format=json "datligent/mcp/shared/$API_NAME" 2>/dev/null || echo "{}")

if [ "$SECRET" = "{}" ]; then
  echo "❌ Secret not found: datligent/mcp/shared/$API_NAME"
  echo ""
  echo "Create it with:"
  echo "  vault kv put datligent/mcp/shared/$API_NAME \\"
  echo "    authorization=\"Bearer your-token\" \\"
  echo "    swagger_url=\"https://api.example.com/openapi.json\""
  exit 1
fi

AUTH=$(echo "$SECRET" | jq -r '.data.data.authorization // empty')
SWAGGER=$(echo "$SECRET" | jq -r '.data.data.swagger_url // empty')
DESC=$(echo "$SECRET" | jq -r '.data.data.description // empty')

if [ -z "$AUTH" ]; then
  echo "❌ No 'authorization' field in secret: $API_NAME"
  exit 1
fi

echo "✅ Configuration for: $API_NAME"
echo ""
if [ -n "$DESC" ]; then
  echo "📝 Description: $DESC"
fi
echo ""
echo "📋 Docker Desktop Configuration:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "api_1_name:"
echo "  $API_NAME"
echo ""
if [ -n "$SWAGGER" ]; then
  echo "api_1_swagger_url:"
  echo "  $SWAGGER"
  echo ""
fi
echo "api_1_header_authorization:"
echo "  $AUTH"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "👉 Copy the values above into Docker Desktop MCP configuration"
