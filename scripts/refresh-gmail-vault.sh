#!/bin/bash
# Refresh Gmail credentials in Vault
# Met à jour le refresh_token Gmail dans Vault

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "╔═══════════════════════════════════╗"
echo "║  REFRESH GMAIL VAULT              ║"
echo "╚═══════════════════════════════════╝"
echo ""

# Configuration
export VAULT_ADDR="${VAULT_ADDR:-http://localhost:8200}"
export VAULT_TOKEN="${VAULT_TOKEN:-$(cat /Users/adminmac/vault-datligent/init-data/vault-init.json | jq -r '.root_token')}"

# Vérifier que les variables d'environnement sont définies
if [ -z "${GMAIL_CLIENT_ID:-}" ] || [ -z "${GMAIL_CLIENT_SECRET:-}" ] || [ -z "${GMAIL_REFRESH_TOKEN:-}" ]; then
  echo -e "${RED}❌ Gmail environment variables not set${NC}"
  echo ""
  echo "Required variables:"
  echo "   - GMAIL_CLIENT_ID"
  echo "   - GMAIL_CLIENT_SECRET"
  echo "   - GMAIL_REFRESH_TOKEN"
  echo ""
  echo "Solution:"
  echo "   1. Run: ./scripts/get_new_tokens.sh"
  echo "   2. Source the output: source /tmp/gmail-tokens.env"
  echo "   3. Run this script again"
  exit 1
fi

echo "🔍 Credentials to update:"
echo "   Client ID: ${GMAIL_CLIENT_ID:0:30}..."
echo "   Client Secret: ${GMAIL_CLIENT_SECRET:0:20}..."
echo "   Refresh Token: ${GMAIL_REFRESH_TOKEN:0:30}..."
echo ""

# Tester le nouveau token avant de l'enregistrer
echo "🔍 Testing new token..."
RESP=$(curl -s -X POST "https://oauth2.googleapis.com/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "client_id=${GMAIL_CLIENT_ID}" \
  --data-urlencode "client_secret=${GMAIL_CLIENT_SECRET}" \
  --data-urlencode "refresh_token=${GMAIL_REFRESH_TOKEN}" \
  --data-urlencode "grant_type=refresh_token" 2>/dev/null || echo '{}')

ERR=$(echo "$RESP" | jq -r '.error // empty' 2>/dev/null || true)
if [ -n "$ERR" ]; then
  echo -e "${RED}❌ Token is INVALID: $ERR${NC}"
  exit 1
fi
echo -e "${GREEN}✅ Token is valid${NC}"

# Mettre à jour Vault
echo ""
echo "🔧 Updating Vault..."
vault kv put datligent/mcp/shared/gmail \
  client_id="${GMAIL_CLIENT_ID}" \
  client_secret="${GMAIL_CLIENT_SECRET}" \
  refresh_token="${GMAIL_REFRESH_TOKEN}" \
  description="Gmail OAuth credentials for MCP tools"

echo -e "${GREEN}✅ Vault updated successfully${NC}"

# Vérifier
echo ""
echo "🔍 Verifying update..."
./scripts/test-gmail-vault.sh

echo ""
echo "╔═══════════════════════════════════╗"
echo "║  REFRESH COMPLETE ✅              ║"
echo "╚═══════════════════════════════════╝"
