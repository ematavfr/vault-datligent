# Politique d'accès pour tous les outils IA (Claude Code, Cursor, Gemini-CLI, Codex, etc.)
# Cette politique permet un accès complet aux secrets MCP partagés

# Accès complet aux secrets MCP partagés
path "datligent/mcp/data/shared/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Accès aux métadonnées des secrets partagés
path "datligent/mcp/metadata/shared/*" {
  capabilities = ["read", "list"]
}

# Permet de lister les secrets
path "datligent/mcp/metadata" {
  capabilities = ["list"]
}

# Accès en lecture seule aux secrets spécifiques des autres outils
path "datligent/mcp/data/+/*" {
  capabilities = ["read", "list"]
}

# Accès aux métadonnées des secrets spécifiques
path "datligent/mcp/metadata/+/*" {
  capabilities = ["read", "list"]
}

# Permet de renouveler son propre token
path "auth/token/renew-self" {
  capabilities = ["update"]
}

# Permet de consulter les informations de son propre token
path "auth/token/lookup-self" {
  capabilities = ["read"]
}
