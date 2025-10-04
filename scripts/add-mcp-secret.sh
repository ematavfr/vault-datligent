#!/bin/bash

# Script pour ajouter facilement de nouveaux secrets MCP
# Usage: ./add-mcp-secret.sh <service> <key1>=<value1> [key2=value2 ...]

set -e

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration Vault
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="datligent-root-token"

if [ $# -lt 2 ]; then
    echo -e "${RED}Usage: $0 <service> <key1>=<value1> [key2=value2 ...]${NC}"
    echo ""
    echo -e "${BLUE}Examples:${NC}"
    echo "  $0 deepl api_key='sk-abc123...'"
    echo "  $0 slack bot_token='xoxb-123...' app_token='xapp-456...'"
    echo "  $0 anthropic api_key='sk-ant-...' model='claude-3-opus'"
    exit 1
fi

SERVICE=$1
shift

# Construire la commande vault kv put
SECRET_PATH="datligent/mcp/shared/$SERVICE"
CMD="vault kv put $SECRET_PATH"

for arg in "$@"; do
    CMD="$CMD $arg"
done

echo -e "${BLUE}🔐 Ajout du secret pour le service: ${YELLOW}$SERVICE${NC}"
echo -e "${BLUE}📍 Path: ${YELLOW}$SECRET_PATH${NC}"
echo ""

# Exécuter la commande
eval $CMD

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Secret ajouté avec succès !${NC}"
    echo ""
    echo -e "${BLUE}📖 Vous pouvez maintenant y accéder depuis vos outils IA avec:${NC}"
    echo -e "   ${YELLOW}\"Récupère les secrets $SERVICE depuis Vault\"${NC}"
    echo ""
    echo -e "${BLUE}🔍 Pour vérifier:${NC}"
    echo "   vault kv get $SECRET_PATH"
else
    echo -e "${RED}❌ Erreur lors de l'ajout du secret${NC}"
    exit 1
fi
