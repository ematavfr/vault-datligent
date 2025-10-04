#!/bin/bash
# Script helper pour récupérer un secret depuis Vault
# Usage: ./get-secret.sh <service> [field]

set -e

SERVICE=$1
FIELD=$2

if [ -z "$SERVICE" ]; then
    echo "Usage: $0 <service> [field]"
    echo "Example: $0 github personal_access_token"
    exit 1
fi

export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="${VAULT_TOKEN:-your-vault-token-here}"

if [ -n "$FIELD" ]; then
    vault kv get -field="$FIELD" "datligent/mcp/shared/$SERVICE"
else
    vault kv get "datligent/mcp/shared/$SERVICE"
fi
