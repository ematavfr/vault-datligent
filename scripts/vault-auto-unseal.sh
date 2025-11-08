#!/bin/bash
# Auto-unseal Vault au démarrage
# Ce script attend que Vault soit prêt puis le déscelle automatiquement

set -euo pipefail

LOG_FILE="/Users/adminmac/vault-datligent/vault-logs/auto-unseal.log"
VAULT_ADDR="http://localhost:8200"
INIT_FILE="/Users/adminmac/vault-datligent/init-data/vault-init.json"
MAX_RETRIES=60
RETRY_DELAY=3

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "========================================"
log "Vault Auto-Unseal Starting"
log "========================================"

# Attendre que Vault API soit accessible
log "Waiting for Vault API..."
retry=0
while ! curl -s "${VAULT_ADDR}/v1/sys/health" >/dev/null 2>&1; do
    retry=$((retry + 1))
    if [ $retry -ge $MAX_RETRIES ]; then
        log "ERROR: Vault API not accessible after ${MAX_RETRIES} retries"
        exit 1
    fi
    [ $((retry % 10)) -eq 0 ] && log "Still waiting for Vault API... retry $retry/$MAX_RETRIES"
    sleep $RETRY_DELAY
done
log "✅ Vault API is accessible"

# Vérifier si Vault est scellé
export VAULT_ADDR="$VAULT_ADDR"
HEALTH=$(curl -s "${VAULT_ADDR}/v1/sys/health")
SEALED=$(echo "$HEALTH" | jq -r '.sealed // true')

if [ "$SEALED" = "false" ]; then
    log "✅ Vault is already unsealed, nothing to do"
    exit 0
fi

log "Vault is sealed, proceeding with auto-unseal..."

# Lire la clé de déscellement
if [ ! -f "$INIT_FILE" ]; then
    log "ERROR: Init file not found: $INIT_FILE"
    exit 1
fi

UNSEAL_KEY=$(jq -r '.unseal_keys_b64[0]' "$INIT_FILE")
if [ -z "$UNSEAL_KEY" ] || [ "$UNSEAL_KEY" = "null" ]; then
    log "ERROR: Cannot read unseal key from $INIT_FILE"
    exit 1
fi

# Désceller Vault
log "Unsealing Vault..."
if vault operator unseal "$UNSEAL_KEY" >/dev/null 2>&1; then
    log "✅ Vault unsealed successfully"
else
    log "ERROR: Failed to unseal Vault"
    exit 1
fi

# Vérifier que Vault est bien déscellé
sleep 3
HEALTH=$(curl -s "${VAULT_ADDR}/v1/sys/health" 2>/dev/null || echo '{"sealed":true}')
SEALED=$(echo "$HEALTH" | jq -r '.sealed // true' 2>/dev/null || echo "true")

if [ "$SEALED" = "false" ]; then
    log "✅ Vault status confirmed: unsealed"
elif vault status 2>&1 | grep -q "Sealed.*false"; then
    log "✅ Vault status confirmed: unsealed (via vault status)"
else
    log "⚠️  Could not confirm unseal status, but unseal command succeeded"
fi

log "========================================"
log "Vault Auto-Unseal Complete"
log "========================================"
