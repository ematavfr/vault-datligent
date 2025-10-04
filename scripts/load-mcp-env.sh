#!/bin/bash

# Script pour charger les variables d'environnement depuis Vault
# Usage: eval $(./scripts/load-mcp-env.sh)

set -e

# Configuration Vault
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="${VAULT_AI_TOOLS_TOKEN:-hvs.CAESIJ2g4d__dzguoAWIzuNzyhFtbO9Hk5gUUU1xT4RRbAs2Gh4KHGh2cy56MzBkVWVBM21MOE9zdEg3c3lncFB1c3Q}"

# Fonction pour récupérer un secret
get_secret() {
    local service=$1
    local field=$2
    vault kv get -field="$field" "datligent/mcp/shared/$service" 2>/dev/null || echo ""
}

# Charger tous les secrets
echo "# Secrets MCP chargés depuis Vault"

# Brave Search
BRAVE_API_KEY=$(get_secret "brave-search" "api_key")
[ -n "$BRAVE_API_KEY" ] && echo "export BRAVE_API_KEY='$BRAVE_API_KEY'"

# Airtable
AIRTABLE_API_KEY=$(get_secret "airtable" "api_key")
[ -n "$AIRTABLE_API_KEY" ] && echo "export AIRTABLE_API_KEY='$AIRTABLE_API_KEY'"

# GitHub
GITHUB_PERSONAL_ACCESS_TOKEN=$(get_secret "github" "personal_access_token")
[ -n "$GITHUB_PERSONAL_ACCESS_TOKEN" ] && echo "export GITHUB_PERSONAL_ACCESS_TOKEN='$GITHUB_PERSONAL_ACCESS_TOKEN'"

# Tavily
TAVILY_API_KEY=$(get_secret "tavily" "api_key")
[ -n "$TAVILY_API_KEY" ] && echo "export TAVILY_API_KEY='$TAVILY_API_KEY'"

# AWS
AWS_ACCESS_KEY_ID=$(get_secret "aws" "access_key_id")
AWS_SECRET_ACCESS_KEY=$(get_secret "aws" "secret_access_key")
AWS_DEFAULT_REGION=$(get_secret "aws" "default_region")
[ -n "$AWS_ACCESS_KEY_ID" ] && echo "export AWS_ACCESS_KEY_ID='$AWS_ACCESS_KEY_ID'"
[ -n "$AWS_SECRET_ACCESS_KEY" ] && echo "export AWS_SECRET_ACCESS_KEY='$AWS_SECRET_ACCESS_KEY'"
[ -n "$AWS_DEFAULT_REGION" ] && echo "export AWS_DEFAULT_REGION='$AWS_DEFAULT_REGION'"

# DeepL (déjà existant, on utilise la valeur actuelle ou celle de Vault)
DEEPL_API_KEY=$(get_secret "deepl" "api_key")
[ -n "$DEEPL_API_KEY" ] && echo "export DEEPL_API_KEY='$DEEPL_API_KEY'"

# GitLab
GITLAB_PERSONAL_ACCESS_TOKEN=$(get_secret "gitlab" "personal_access_token")
GITLAB_API_URL=$(get_secret "gitlab" "api_url")
[ -n "$GITLAB_PERSONAL_ACCESS_TOKEN" ] && echo "export GITLAB_PERSONAL_ACCESS_TOKEN='$GITLAB_PERSONAL_ACCESS_TOKEN'"
[ -n "$GITLAB_API_URL" ] && echo "export GITLAB_API_URL='$GITLAB_API_URL'"

# OpenAI (si existe)
OPENAI_API_KEY=$(get_secret "openai" "api_key")
[ -n "$OPENAI_API_KEY" ] && echo "export OPENAI_API_KEY='$OPENAI_API_KEY'"

# Composio (si existe)
COMPOSIO_API_KEY=$(get_secret "composio" "api_key")
[ -n "$COMPOSIO_API_KEY" ] && echo "export COMPOSIO_API_KEY='$COMPOSIO_API_KEY'"
