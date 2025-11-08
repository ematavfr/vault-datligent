#!/bin/bash
# Vault Health Check Script
# Vérifie la santé du cluster Vault et des secrets MCP

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "╔═══════════════════════════════════╗"
echo "║  VAULT HEALTH CHECK               ║"
echo "╚═══════════════════════════════════╝"
echo ""

# Configuration
export VAULT_ADDR="${VAULT_ADDR:-http://localhost:8200}"
export VAULT_TOKEN="${VAULT_TOKEN:-$(cat /Users/adminmac/vault-datligent/init-data/vault-init.json | jq -r '.root_token')}"

# 1. Vérifier que Vault est accessible
echo "🔍 Checking Vault accessibility..."
if ! curl -s -f "${VAULT_ADDR}/v1/sys/health" > /dev/null 2>&1; then
  echo -e "${RED}❌ Vault is not accessible at ${VAULT_ADDR}${NC}"
  exit 1
fi
echo -e "${GREEN}✅ Vault is accessible${NC}"

# 2. Vérifier le statut de Vault
echo ""
echo "🔍 Checking Vault status..."
STATUS=$(vault status -format=json 2>/dev/null || echo '{}')
SEALED=$(echo "$STATUS" | jq -r '.sealed // true')
INITIALIZED=$(echo "$STATUS" | jq -r '.initialized // false')

if [ "$INITIALIZED" = "false" ]; then
  echo -e "${RED}❌ Vault is NOT initialized${NC}"
  exit 1
fi

if [ "$SEALED" = "true" ]; then
  echo -e "${YELLOW}⚠️  Vault is SEALED${NC}"
  echo "   Running auto-unseal..."
  UNSEAL_KEY=$(cat /Users/adminmac/vault-datligent/init-data/vault-init.json | jq -r '.unseal_keys_b64[0]')
  vault operator unseal "$UNSEAL_KEY" > /dev/null 2>&1
  echo -e "${GREEN}✅ Vault unsealed successfully${NC}"
else
  echo -e "${GREEN}✅ Vault is unsealed${NC}"
fi

# 3. Vérifier les conteneurs Docker
echo ""
echo "🔍 Checking Docker containers..."
VAULT_CONTAINER=$(docker ps --filter "name=vault-datligent" --format "{{.Names}}" 2>/dev/null || true)
if [ -z "$VAULT_CONTAINER" ]; then
  echo -e "${RED}❌ Vault container is not running${NC}"
  exit 1
fi
echo -e "${GREEN}✅ Vault container is running: $VAULT_CONTAINER${NC}"

# 4. Lister les secrets MCP
echo ""
echo "🔍 Checking MCP secrets..."
SECRETS=$(vault kv list -format=json datligent/mcp/shared 2>/dev/null | jq -r '.[]' 2>/dev/null || echo "")
if [ -z "$SECRETS" ]; then
  echo -e "${YELLOW}⚠️  No MCP secrets found${NC}"
else
  SECRET_COUNT=$(echo "$SECRETS" | wc -l | tr -d ' ')
  echo -e "${GREEN}✅ Found $SECRET_COUNT MCP secrets:${NC}"
  echo "$SECRETS" | while read -r secret; do
    echo "   - $secret"
  done
fi

# 5. Tester les credentials critiques
echo ""
echo "🔍 Testing critical credentials..."

# Test Gmail
echo -n "   - gmail: "
if vault kv get -format=json datligent/mcp/shared/gmail >/dev/null 2>&1; then
  GMAIL_SECRET=$(vault kv get -format=json datligent/mcp/shared/gmail)
  CLIENT_ID=$(echo "$GMAIL_SECRET" | jq -r '.data.data.client_id // empty')
  REFRESH_TOKEN=$(echo "$GMAIL_SECRET" | jq -r '.data.data.refresh_token // empty')

  if [ -n "$CLIENT_ID" ] && [ -n "$REFRESH_TOKEN" ]; then
    echo -e "${GREEN}OK${NC}"
  else
    echo -e "${YELLOW}INCOMPLETE${NC}"
  fi
else
  echo -e "${RED}MISSING${NC}"
fi

# Test GitHub
echo -n "   - github: "
if vault kv get -format=json datligent/mcp/shared/github >/dev/null 2>&1; then
  echo -e "${GREEN}OK${NC}"
else
  echo -e "${RED}MISSING${NC}"
fi

# Test OpenAI
echo -n "   - openai: "
if vault kv get -format=json datligent/mcp/shared/openai >/dev/null 2>&1; then
  echo -e "${GREEN}OK${NC}"
else
  echo -e "${RED}MISSING${NC}"
fi

echo ""
echo "╔═══════════════════════════════════╗"
echo "║  HEALTH CHECK COMPLETE            ║"
echo "╚═══════════════════════════════════╝"
