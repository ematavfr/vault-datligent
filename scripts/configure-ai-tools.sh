#!/bin/bash

# Script de configuration des outils IA pour accéder à Vault via MCP
# Ce script configure Claude Code, Cursor, Gemini-CLI et Codex

set -e

# Couleurs pour l'affichage
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 Configuration de l'accès Vault pour les outils IA${NC}\n"

# Charger le token depuis le fichier
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOKEN_FILE="${SCRIPT_DIR}/../init-data/ai-tools-token.txt"

if [ ! -f "$TOKEN_FILE" ]; then
    echo -e "${YELLOW}⚠️  Fichier de token introuvable: $TOKEN_FILE${NC}"
    exit 1
fi

# Extraire le token
AI_TOOLS_TOKEN=$(grep "^AI_TOOLS_TOKEN=" "$TOKEN_FILE" | cut -d'=' -f2)

if [ -z "$AI_TOOLS_TOKEN" ]; then
    echo -e "${YELLOW}⚠️  Token introuvable dans le fichier${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Token chargé avec succès${NC}"

# Configuration MCP pour différents outils
MCP_CONFIG='{
  "command": "docker",
  "args": [
    "run",
    "-i",
    "--rm",
    "-e",
    "VAULT_ADDR=http://host.docker.internal:8200",
    "-e",
    "VAULT_TOKEN='$AI_TOOLS_TOKEN'",
    "ashgw/vault-mcp:latest"
  ]
}'

echo -e "\n${BLUE}📋 Configuration MCP Vault:${NC}"
echo "$MCP_CONFIG" | jq .

# Configuration pour Claude Code
echo -e "\n${BLUE}1. Configuration Claude Code${NC}"
if command -v claude &> /dev/null; then
    echo "Suppression de l'ancienne configuration..."
    claude mcp remove vault-mcp 2>/dev/null || true

    echo "Ajout de la nouvelle configuration..."
    echo "$MCP_CONFIG" | claude mcp add-json vault-mcp -

    echo -e "${GREEN}✓ Claude Code configuré${NC}"
else
    echo -e "${YELLOW}⚠️  Claude CLI non trouvé${NC}"
fi

# Configuration pour Cursor
echo -e "\n${BLUE}2. Configuration Cursor${NC}"
CURSOR_CONFIG_DIR="$HOME/.cursor"
if [ -d "$CURSOR_CONFIG_DIR" ]; then
    CURSOR_MCP_FILE="$CURSOR_CONFIG_DIR/mcp-config.json"

    cat > "$CURSOR_MCP_FILE" <<EOF
{
  "vault": {
    "command": "docker",
    "args": [
      "run",
      "-i",
      "--rm",
      "-e",
      "VAULT_ADDR=http://host.docker.internal:8200",
      "-e",
      "VAULT_TOKEN=$AI_TOOLS_TOKEN",
      "ashgw/vault-mcp:latest"
    ]
  }
}
EOF
    echo -e "${GREEN}✓ Cursor configuré${NC}"
else
    echo -e "${YELLOW}⚠️  Répertoire Cursor non trouvé${NC}"
    echo -e "   Créez manuellement la configuration MCP dans les paramètres Cursor"
fi

# Configuration pour Gemini-CLI
echo -e "\n${BLUE}3. Configuration Gemini-CLI${NC}"
GEMINI_CONFIG_DIR="$HOME/.config/gemini-cli"
if [ -d "$GEMINI_CONFIG_DIR" ]; then
    GEMINI_MCP_FILE="$GEMINI_CONFIG_DIR/mcp.json"

    cat > "$GEMINI_MCP_FILE" <<EOF
{
  "servers": {
    "vault": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "-e",
        "VAULT_ADDR=http://host.docker.internal:8200",
        "-e",
        "VAULT_TOKEN=$AI_TOOLS_TOKEN",
        "ashgw/vault-mcp:latest"
      ]
    }
  }
}
EOF
    echo -e "${GREEN}✓ Gemini-CLI configuré${NC}"
else
    echo -e "${YELLOW}⚠️  Répertoire Gemini-CLI non trouvé${NC}"
fi

# Configuration pour Codex
echo -e "\n${BLUE}4. Configuration Codex${NC}"
CODEX_CONFIG_DIR="$HOME/.codex"
if [ -d "$CODEX_CONFIG_DIR" ]; then
    CODEX_MCP_FILE="$CODEX_CONFIG_DIR/mcp-servers.json"

    cat > "$CODEX_MCP_FILE" <<EOF
{
  "vault-mcp": {
    "command": "docker",
    "args": [
      "run",
      "-i",
      "--rm",
      "-e",
      "VAULT_ADDR=http://host.docker.internal:8200",
      "-e",
      "VAULT_TOKEN=$AI_TOOLS_TOKEN",
      "ashgw/vault-mcp:latest"
    ]
  }
}
EOF
    echo -e "${GREEN}✓ Codex configuré${NC}"
else
    echo -e "${YELLOW}⚠️  Répertoire Codex non trouvé${NC}"
fi

# Résumé
echo -e "\n${BLUE}📊 Résumé de la configuration:${NC}"
echo -e "  • Token partagé: ${GREEN}configuré${NC}"
echo -e "  • Politique d'accès: ${GREEN}ai-tools-mcp-access${NC}"
echo -e "  • TTL du token: ${GREEN}768h (32 jours, renouvelable)${NC}"
echo -e "  • Vault URL: ${GREEN}http://localhost:8200${NC}"

echo -e "\n${BLUE}🎯 Utilisation:${NC}"
echo -e "  Tous vos outils IA peuvent maintenant utiliser des commandes naturelles comme:"
echo -e "  ${YELLOW}\"Récupère ma clé API DeepL depuis Vault\"${NC}"
echo -e "  ${YELLOW}\"Affiche tous les tokens GitHub disponibles\"${NC}"
echo -e "  ${YELLOW}\"Crée un nouveau secret pour l'API Composio\"${NC}"

echo -e "\n${GREEN}✅ Configuration terminée avec succès !${NC}"
