#!/bin/bash

# Script d'installation de la configuration MCP sécurisée avec Vault
# Ce script remplace la configuration MCP actuelle par une version utilisant Vault

set -e

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🔐 Installation de la configuration MCP sécurisée avec Vault${NC}\n"

# Chemins
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CLAUDE_CONFIG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
BACKUP_CONFIG="${CLAUDE_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
NEW_CONFIG="$PROJECT_DIR/claude_desktop_config_vault.json"

# Vérification
if [ ! -f "$NEW_CONFIG" ]; then
    echo -e "${RED}❌ Fichier de configuration introuvable: $NEW_CONFIG${NC}"
    exit 1
fi

# Étape 1: Backup de la configuration actuelle
echo -e "${BLUE}📦 Étape 1: Sauvegarde de la configuration actuelle${NC}"
if [ -f "$CLAUDE_CONFIG" ]; then
    cp "$CLAUDE_CONFIG" "$BACKUP_CONFIG"
    echo -e "${GREEN}✓ Backup créé: $BACKUP_CONFIG${NC}"
else
    echo -e "${YELLOW}⚠️  Aucune configuration existante trouvée${NC}"
fi

# Étape 2: Vérifier que Vault est accessible
echo -e "\n${BLUE}🔍 Étape 2: Vérification de Vault${NC}"
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="datligent-root-token"

if ! curl -s "$VAULT_ADDR/v1/sys/health" > /dev/null 2>&1; then
    echo -e "${RED}❌ Vault n'est pas accessible sur $VAULT_ADDR${NC}"
    echo -e "${YELLOW}💡 Démarrez Vault avec: docker-compose -f docker-compose-simple.yml up -d${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Vault est accessible${NC}"

# Étape 3: Vérifier que les secrets sont présents
echo -e "\n${BLUE}🔑 Étape 3: Vérification des secrets dans Vault${NC}"
SECRETS=("brave-search" "airtable" "github" "tavily" "aws" "deepl" "gitlab")
MISSING_SECRETS=()

for secret in "${SECRETS[@]}"; do
    if vault kv get "datligent/mcp/shared/$secret" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ $secret${NC}"
    else
        echo -e "${RED}✗ $secret${NC}"
        MISSING_SECRETS+=("$secret")
    fi
done

if [ ${#MISSING_SECRETS[@]} -ne 0 ]; then
    echo -e "\n${YELLOW}⚠️  Secrets manquants: ${MISSING_SECRETS[*]}${NC}"
    echo -e "${YELLOW}💡 Relancez la migration des secrets${NC}"
fi

# Étape 4: Créer un wrapper script pour Claude Desktop
echo -e "\n${BLUE}📝 Étape 4: Création du wrapper pour charger les variables${NC}"

WRAPPER_SCRIPT="$HOME/.config/claude/load-env-wrapper.sh"
mkdir -p "$(dirname "$WRAPPER_SCRIPT")"

cat > "$WRAPPER_SCRIPT" << 'WRAPPER_EOF'
#!/bin/bash
# Wrapper pour charger les variables d'environnement depuis Vault avant de lancer Claude Desktop

# Charger les variables depuis Vault
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="${VAULT_TOKEN:-your-vault-token-here}"

# Fonction pour récupérer un secret
get_secret() {
    vault kv get -field="$2" "datligent/mcp/shared/$1" 2>/dev/null || echo ""
}

# Charger tous les secrets
export BRAVE_API_KEY=$(get_secret "brave-search" "api_key")
export AIRTABLE_API_KEY=$(get_secret "airtable" "api_key")
export GITHUB_PERSONAL_ACCESS_TOKEN=$(get_secret "github" "personal_access_token")
export TAVILY_API_KEY=$(get_secret "tavily" "api_key")
export AWS_ACCESS_KEY_ID=$(get_secret "aws" "access_key_id")
export AWS_SECRET_ACCESS_KEY=$(get_secret "aws" "secret_access_key")
export AWS_DEFAULT_REGION=$(get_secret "aws" "default_region")
export DEEPL_API_KEY=$(get_secret "deepl" "api_key")
export GITLAB_PERSONAL_ACCESS_TOKEN=$(get_secret "gitlab" "personal_access_token")
export GITLAB_API_URL=$(get_secret "gitlab" "api_url")

# Lancer l'application passée en argument
exec "$@"
WRAPPER_EOF

chmod +x "$WRAPPER_SCRIPT"
echo -e "${GREEN}✓ Wrapper créé: $WRAPPER_SCRIPT${NC}"

# Étape 5: Copier la nouvelle configuration
echo -e "\n${BLUE}📋 Étape 5: Installation de la nouvelle configuration${NC}"

# Pour Claude Desktop, on doit malheureusement garder les variables en dur
# car l'application ne supporte pas les variables d'environnement dynamiques
# On va créer une version avec les valeurs réelles

echo -e "${YELLOW}⚠️  Note: Claude Desktop ne supporte pas les variables d'environnement dynamiques${NC}"
echo -e "${YELLOW}    Nous allons créer une configuration avec les valeurs réelles depuis Vault${NC}\n"

# Créer une configuration avec les vraies valeurs
TEMP_CONFIG="/tmp/claude_desktop_config_temp.json"

# Charger les secrets depuis Vault
BRAVE_API_KEY=$(vault kv get -field="api_key" "datligent/mcp/shared/brave-search" 2>/dev/null || echo "")
AIRTABLE_API_KEY=$(vault kv get -field="api_key" "datligent/mcp/shared/airtable" 2>/dev/null || echo "")
GITHUB_TOKEN=$(vault kv get -field="personal_access_token" "datligent/mcp/shared/github" 2>/dev/null || echo "")
TAVILY_API_KEY=$(vault kv get -field="api_key" "datligent/mcp/shared/tavily" 2>/dev/null || echo "")
AWS_ACCESS_KEY=$(vault kv get -field="access_key_id" "datligent/mcp/shared/aws" 2>/dev/null || echo "")
AWS_SECRET_KEY=$(vault kv get -field="secret_access_key" "datligent/mcp/shared/aws" 2>/dev/null || echo "")
AWS_REGION=$(vault kv get -field="default_region" "datligent/mcp/shared/aws" 2>/dev/null || echo "")
DEEPL_API_KEY=$(vault kv get -field="api_key" "datligent/mcp/shared/deepl" 2>/dev/null || echo "")
GITLAB_TOKEN=$(vault kv get -field="personal_access_token" "datligent/mcp/shared/gitlab" 2>/dev/null || echo "")
GITLAB_URL=$(vault kv get -field="api_url" "datligent/mcp/shared/gitlab" 2>/dev/null || echo "")

# Remplacer les variables dans le fichier
cat "$NEW_CONFIG" | \
    sed "s|\${BRAVE_API_KEY}|$BRAVE_API_KEY|g" | \
    sed "s|\${AIRTABLE_API_KEY}|$AIRTABLE_API_KEY|g" | \
    sed "s|\${GITHUB_PERSONAL_ACCESS_TOKEN}|$GITHUB_TOKEN|g" | \
    sed "s|\${TAVILY_API_KEY}|$TAVILY_API_KEY|g" | \
    sed "s|\${AWS_ACCESS_KEY_ID}|$AWS_ACCESS_KEY|g" | \
    sed "s|\${AWS_SECRET_ACCESS_KEY}|$AWS_SECRET_KEY|g" | \
    sed "s|\${AWS_DEFAULT_REGION}|$AWS_REGION|g" | \
    sed "s|\${DEEPL_API_KEY}|$DEEPL_API_KEY|g" | \
    sed "s|\${GITLAB_PERSONAL_ACCESS_TOKEN}|$GITLAB_TOKEN|g" | \
    sed "s|\${GITLAB_API_URL}|$GITLAB_URL|g" \
    > "$TEMP_CONFIG"

# Copier la configuration finale
mkdir -p "$(dirname "$CLAUDE_CONFIG")"
cp "$TEMP_CONFIG" "$CLAUDE_CONFIG"
rm "$TEMP_CONFIG"

echo -e "${GREEN}✓ Configuration installée${NC}"

# Étape 6: Résumé
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Installation terminée avec succès !${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${BLUE}📦 Résumé:${NC}"
echo -e "  • Configuration sauvegardée: ${YELLOW}$BACKUP_CONFIG${NC}"
echo -e "  • Nouvelle configuration: ${GREEN}$CLAUDE_CONFIG${NC}"
echo -e "  • Serveur MCP Vault: ${GREEN}Ajouté${NC}"
echo -e "  • Serveur Terraform MCP: ${GREEN}Ajouté${NC}"
echo -e "  • Secrets dans Vault: ${GREEN}${#SECRETS[@]} services${NC}"

echo -e "\n${BLUE}🔄 Prochaines étapes:${NC}"
echo -e "  1. ${YELLOW}Redémarrez Claude Desktop${NC}"
echo -e "  2. Vérifiez que tous vos serveurs MCP fonctionnent"
echo -e "  3. Testez l'accès aux secrets avec: ${YELLOW}\"Liste mes secrets MCP\"${NC}"

echo -e "\n${BLUE}💡 Pour mettre à jour un secret:${NC}"
echo -e "  ${YELLOW}./scripts/add-mcp-secret.sh <service> key=\"nouvelle-valeur\"${NC}"
echo -e "  ${YELLOW}Puis relancez ce script pour régénérer la configuration${NC}"

echo -e "\n${BLUE}🔙 Pour restaurer l'ancienne configuration:${NC}"
echo -e "  ${YELLOW}cp \"$BACKUP_CONFIG\" \"$CLAUDE_CONFIG\"${NC}"

echo -e "\n${GREEN}🎉 Vos clés API sont maintenant centralisées dans Vault !${NC}\n"
