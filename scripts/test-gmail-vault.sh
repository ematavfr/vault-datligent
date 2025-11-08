#!/bin/bash
# Test Gmail OAuth credentials from Vault
# Vérifie que le refresh_token Gmail est valide

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "╔═══════════════════════════════════╗"
echo "║  GMAIL OAUTH TOKEN TEST           ║"
echo "╚═══════════════════════════════════╝"
echo ""

# Configuration
export VAULT_ADDR="${VAULT_ADDR:-http://localhost:8200}"
export VAULT_TOKEN="${VAULT_TOKEN:-$(cat /Users/adminmac/vault-datligent/init-data/vault-init.json | jq -r '.root_token')}"

# 1. Vérifier que Vault est accessible
echo "🔍 Checking Vault accessibility..."
if ! vault status >/dev/null 2>&1; then
  echo -e "${RED}❌ Vault is not accessible${NC}"
  echo "   Run: ./scripts/vault-health-check.sh"
  exit 1
fi
echo -e "${GREEN}✅ Vault is accessible${NC}"

# 2. Récupérer les credentials Gmail
echo ""
echo "🔍 Fetching Gmail credentials from Vault..."
GMAIL_SECRET=$(vault kv get -format=json datligent/mcp/shared/gmail 2>/dev/null || echo '{}')

CLIENT_ID=$(echo "$GMAIL_SECRET" | jq -r '.data.data.client_id // empty')
CLIENT_SECRET=$(echo "$GMAIL_SECRET" | jq -r '.data.data.client_secret // empty')
REFRESH_TOKEN=$(echo "$GMAIL_SECRET" | jq -r '.data.data.refresh_token // empty')

if [ -z "$CLIENT_ID" ] || [ -z "$CLIENT_SECRET" ] || [ -z "$REFRESH_TOKEN" ]; then
  echo -e "${RED}❌ Gmail credentials incomplete in Vault${NC}"
  echo "   Missing: $([ -z "$CLIENT_ID" ] && echo "client_id ") $([ -z "$CLIENT_SECRET" ] && echo "client_secret ") $([ -z "$REFRESH_TOKEN" ] && echo "refresh_token")"
  exit 1
fi
echo -e "${GREEN}✅ Gmail credentials found${NC}"
echo "   Client ID: ${CLIENT_ID:0:30}..."
echo "   Refresh Token: ${REFRESH_TOKEN:0:30}..."

# 3. Tester le refresh token
echo ""
echo "🔍 Testing OAuth refresh token..."
RESP=$(curl -s -X POST "https://oauth2.googleapis.com/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "client_id=${CLIENT_ID}" \
  --data-urlencode "client_secret=${CLIENT_SECRET}" \
  --data-urlencode "refresh_token=${REFRESH_TOKEN}" \
  --data-urlencode "grant_type=refresh_token" 2>/dev/null || echo '{}')

ERR=$(echo "$RESP" | jq -r '.error // empty' 2>/dev/null || true)
if [ -n "$ERR" ]; then
  echo -e "${RED}❌ OAuth ERROR: $ERR${NC}"
  ERR_DESC=$(echo "$RESP" | jq -r '.error_description // empty' 2>/dev/null || true)
  if [ -n "$ERR_DESC" ]; then
    echo "   Description: $ERR_DESC"
  fi
  echo ""
  echo "🔧 SOLUTION:"
  if [ "$ERR" = "invalid_grant" ]; then
    echo "   The refresh token is expired or revoked."
    echo "   1. Generate new token: ./scripts/get_new_tokens.sh"
    echo "   2. Update Vault: ./scripts/refresh-gmail-vault.sh"
  else
    echo "   Check your OAuth client configuration in Google Console"
  fi
  exit 1
fi

ACCESS_TOKEN=$(echo "$RESP" | jq -r '.access_token // empty' 2>/dev/null || true)
if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" = "null" ]; then
  echo -e "${RED}❌ No access_token received${NC}"
  echo "$RESP" | jq .
  exit 1
fi

EXPIRES_IN=$(echo "$RESP" | jq -r '.expires_in // 0' 2>/dev/null || echo "0")
echo -e "${GREEN}✅ Gmail OAuth token is VALID${NC}"
echo "   Access Token: ${ACCESS_TOKEN:0:30}..."
echo "   Expires In: ${EXPIRES_IN}s (~$((EXPIRES_IN / 60)) minutes)"

echo ""
echo "╔═══════════════════════════════════╗"
echo "║  TEST PASSED ✅                   ║"
echo "╚═══════════════════════════════════╝"
