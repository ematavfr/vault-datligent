#!/bin/bash

# Script pour lister et afficher tous les secrets MCP
# Usage: ./list-mcp-secrets.sh [service]

set -e

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration Vault
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="datligent-root-token"

echo -e "${BLUE}🔐 Secrets MCP disponibles dans Vault${NC}\n"

# Fonction pour afficher un secret
show_secret() {
    local service=$1
    echo -e "${CYAN}📦 Service: ${YELLOW}$service${NC}"
    echo -e "${CYAN}   Path: ${NC}datligent/mcp/shared/$service"

    # Récupérer les clés du secret
    local secret_data=$(vault kv get -format=json datligent/mcp/shared/$service 2>/dev/null)

    if [ $? -eq 0 ]; then
        echo -e "${CYAN}   Clés:${NC}"
        echo "$secret_data" | jq -r '.data.data | keys[]' | while read key; do
            # Afficher la clé avec valeur masquée
            local value=$(echo "$secret_data" | jq -r ".data.data.$key")
            local masked_value="${value:0:8}..."
            echo -e "      • ${GREEN}$key${NC}: $masked_value"
        done

        # Afficher les métadonnées
        local created=$(echo "$secret_data" | jq -r '.data.metadata.created_time')
        local version=$(echo "$secret_data" | jq -r '.data.metadata.version')
        echo -e "${CYAN}   Metadata:${NC}"
        echo -e "      • Version: $version"
        echo -e "      • Créé: $created"
    else
        echo -e "      ${YELLOW}⚠️  Secret non trouvé${NC}"
    fi
    echo ""
}

# Si un service spécifique est demandé
if [ $# -eq 1 ]; then
    show_secret "$1"
    echo -e "${BLUE}💡 Pour voir la valeur complète:${NC}"
    echo "   vault kv get datligent/mcp/shared/$1"
    exit 0
fi

# Lister tous les services
echo -e "${BLUE}📋 Liste des services configurés:${NC}\n"

services=$(vault kv list -format=json datligent/mcp/shared 2>/dev/null | jq -r '.[]')

if [ -z "$services" ]; then
    echo -e "${YELLOW}⚠️  Aucun secret trouvé${NC}"
    echo ""
    echo -e "${BLUE}💡 Pour ajouter un secret:${NC}"
    echo "   ./add-mcp-secret.sh <service> key=value"
    exit 0
fi

# Afficher chaque service
echo "$services" | while read service; do
    show_secret "$service"
done

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 Total: ${YELLOW}$(echo "$services" | wc -l | tr -d ' ')${BLUE} service(s) configuré(s)${NC}"
echo ""
echo -e "${BLUE}💡 Commandes utiles:${NC}"
echo "   • Afficher un secret spécifique: $0 <service>"
echo "   • Voir la valeur complète: vault kv get datligent/mcp/shared/<service>"
echo "   • Ajouter un secret: ./add-mcp-secret.sh <service> key=value"
echo ""
echo -e "${BLUE}🎯 Depuis vos outils IA:${NC}"
echo -e "   ${YELLOW}\"Liste tous mes secrets MCP\"${NC}"
echo -e "   ${YELLOW}\"Affiche le secret pour <service>\"${NC}"
