# Plan de Migration MCP vers Docker Desktop + Vault

## 🎯 Objectif

Migrer tous les serveurs MCP de la configuration **Claude Desktop** vers **Docker MCP** avec secrets gérés par **Vault**.

## 📊 État Actuel

### Configuration Claude Desktop (`claude_desktop_config.json`)

**Serveurs MCP actuels** : 19 serveurs

#### Catégories identifiées :

**1. Serveurs avec secrets hardcodés** ⚠️ (PRIORITÉ HAUTE)
- `vault-mcp` - Token Vault en clair
- `airtable` - API Key en clair
- `aws-resources` - Access Key + Secret en clair
- `deepl` - API Key en clair
- `context7-mcp` - Key en clair
- `mcp-neo4j-memory-server` - Key en clair

**2. Serveurs Docker natifs** ✅ (FACILE)
- `gmail` - Docker (buryhuang/mcp-headless-gmail)
- `aws-resources` - Docker (buryhuang/mcp-server-aws-resources)
- `terraform` - Docker (hashicorp/terraform-mcp-server)
- `MCP_DOCKER` - Gateway Docker MCP

**3. Serveurs NPX** 🔄 (MOYENNE)
- `airtable` - npx @felores/airtable-mcp-server
- `mcp-compass` - npx @liuyoshio/mcp-compass
- `context7-mcp` - npx @smithery/cli
- `mcp-neo4j-memory-server` - npx @smithery/cli
- `deepl` - npx deepl-mcp-server
- `chrome-devtools` - npx chrome-devtools-mcp
- `tailwind-docs` - npx mcp-remote
- `react-docs` - npx mcp-remote
- `nextjs-docs` - npx mcp-remote
- `dynamic-docs` - npx mcp-remote

**4. Serveurs locaux** 🏠 (SPÉCIAL)
- `desktopCommander` - Node local (/Users/adminmac/ClaudeComputerCommander)
- `vault-mcp` - Node local (vault-mcp-wrapper.js)
- `leann-server` - Python local (.venv/bin/leann_mcp)

### Serveurs Docker MCP existants

**19 serveurs disponibles** :
```
aws-core-mcp-server, brave, context7, desktop-commander, docker,
duckduckgo, filesystem, firecrawl, github-official, gitlab,
markdownify, mcp-api-gateway, notion, puppeteer, rube,
rust-mcp-filesystem, tavily, terraform, youtube_transcript
```

### Secrets Vault actuels

**10 secrets MCP dans Vault** (`datligent/mcp/shared/`):
```
airtable, aws, brave-search, composio, deepl, github,
gitlab, gmail, openai, tavily
```

## 🗺️ Plan de Migration

### Phase 1 : Préparation (ACTUEL)

**✅ Complété** :
- Vault opérationnel et auto-unseal configuré
- Secrets MCP de base créés dans Vault
- Scripts de troubleshooting créés

**⏳ À faire** :
- Auditer tous les serveurs Claude Desktop
- Identifier les mappings Vault ↔ Docker MCP
- Créer les secrets manquants dans Vault

### Phase 2 : Migration des Secrets vers Vault

**Objectif** : Tous les secrets dans Vault, aucun hardcodé

**Secrets à créer dans Vault** :
```bash
# Context7
vault kv put datligent/mcp/shared/context7 \
  key="712aae3a-48c8-4f68-a5e3-a033a7ed5a34"

# Neo4j Memory
vault kv put datligent/mcp/shared/neo4j-memory \
  key="50c77907-16bc-44d1-8e0b-1c7e78aa59b0"

# Vérifier les existants
vault kv get datligent/mcp/shared/airtable
vault kv get datligent/mcp/shared/aws
vault kv get datligent/mcp/shared/deepl
```

### Phase 3 : Configuration Docker MCP

**Objectif** : Configurer chaque serveur dans Docker MCP avec secrets Vault

#### 3.1 Serveurs déjà dans Docker MCP

**Serveurs disponibles** :
- ✅ `brave` (brave-search dans Vault)
- ✅ `github-official` (github dans Vault)
- ✅ `gitlab` (gitlab dans Vault)
- ✅ `tavily` (tavily dans Vault)
- ✅ `terraform` (pas de secret requis)
- ✅ `rube` (composio dans Vault)
- ✅ `context7` (à créer dans Vault)

**Commandes de configuration** :
```bash
# Exemple : Brave avec secret Vault
docker mcp secret set brave-search \
  --vault-path=datligent/mcp/shared/brave-search

# Activer le serveur
docker mcp server enable brave
```

#### 3.2 Serveurs à ajouter au catalogue Docker MCP

**Candidats pour dockerisation** :
- `airtable` - NPX → Docker
- `deepl` - NPX → Docker (priorité car secret)
- `gmail` - Déjà Docker mais via Claude Desktop

### Phase 4 : Migration Progressive

**Stratégie** : Migration serveur par serveur avec validation

**Ordre de migration** :
1. **Serveurs sans secrets** (facile, pas de risque)
   - terraform ✅
   - chrome-devtools
   - docs servers (tailwind, react, nextjs, dynamic)

2. **Serveurs avec secrets dans Vault** (moyenne difficulté)
   - brave-search
   - github-official
   - gitlab
   - tavily
   - airtable
   - deepl
   - aws

3. **Serveurs spéciaux** (complexe)
   - gmail (OAuth)
   - vault-mcp (auto-référence)
   - desktopCommander (local)
   - leann-server (local)

**Process de migration** :
```bash
# 1. Tester le serveur dans Docker MCP
docker mcp server test <server-name>

# 2. Configurer les secrets si nécessaire
docker mcp secret set <secret-name> --vault-path=...

# 3. Activer le serveur
docker mcp server enable <server-name>

# 4. Vérifier dans Claude Desktop
# Remplacer l'entrée par MCP_DOCKER gateway

# 5. Tester dans Claude Desktop

# 6. Si OK, supprimer l'ancienne entrée
```

### Phase 5 : Nouvelle Configuration Claude Desktop

**Configuration cible** :
```json
{
  "mcpServers": {
    "MCP_DOCKER": {
      "command": "docker",
      "args": ["mcp", "gateway", "run", "--transport=stdio"],
      "env": {}
    },
    "vault-mcp": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-e", "VAULT_ADDR=http://host.docker.internal:8200",
        "-e", "VAULT_TOKEN=<from-vault>",
        "ashgw/vault-mcp:latest"
      ]
    },
    "desktopCommander": {
      "comment": "Serveur local spécial, pas de migration",
      "command": "node",
      "args": ["/Users/adminmac/ClaudeComputerCommander/dist/index.js"]
    },
    "leann-server": {
      "comment": "Serveur local Python, pas de migration",
      "command": "/Users/adminmac/leann/.venv/bin/leann_mcp"
    }
  }
}
```

**Résultat** : 4 entrées au lieu de 19 !

### Phase 6 : Intégration Vault ↔ Docker MCP

**Objectif** : Docker MCP lit les secrets depuis Vault automatiquement

**Configuration Docker MCP avec Vault** :
```bash
# Configurer Vault comme backend de secrets
docker mcp config set vault.addr http://localhost:8200
docker mcp config set vault.token <vault-token>

# Policy pour Docker MCP
docker mcp policy create docker-mcp-access \
  --vault-policy=ai-tools-mcp-access
```

## 📋 Matrice de Migration

| Serveur | Type | Secret? | Vault Path | Docker MCP | Priorité | Status |
|---------|------|---------|------------|------------|----------|--------|
| terraform | Docker | Non | - | ✅ Disponible | 1-Facile | 🔲 TODO |
| brave | Docker | Oui | brave-search | ✅ Disponible | 2-Moyen | 🔲 TODO |
| github-official | Docker | Oui | github | ✅ Disponible | 2-Moyen | 🔲 TODO |
| gitlab | Docker | Oui | gitlab | ✅ Disponible | 2-Moyen | 🔲 TODO |
| tavily | Docker | Oui | tavily | ✅ Disponible | 2-Moyen | 🔲 TODO |
| airtable | NPX | Oui | airtable | ❌ À créer | 2-Moyen | 🔲 TODO |
| deepl | NPX | Oui | deepl | ❌ À créer | 2-Moyen | 🔲 TODO |
| aws-resources | Docker | Oui | aws | ✅ Disponible | 2-Moyen | 🔲 TODO |
| gmail | Docker | OAuth | gmail | ❌ Complexe | 3-Hard | 🔲 TODO |
| context7 | NPX | Oui | context7 | ✅ Disponible | 2-Moyen | 🔲 TODO |
| neo4j-memory | NPX | Oui | neo4j-memory | ❌ À créer | 2-Moyen | 🔲 TODO |
| chrome-devtools | NPX | Non | - | ❌ À créer | 1-Facile | 🔲 TODO |
| mcp-compass | NPX | Non | - | ❌ À créer | 1-Facile | 🔲 TODO |
| docs (4×) | NPX | Non | - | ❌ À créer | 1-Facile | 🔲 TODO |
| vault-mcp | Local | - | - | 🔄 Spécial | 4-Spécial | 🔲 TODO |
| desktopCommander | Local | - | - | ⛔ Pas migré | 5-Skip | ✅ SKIP |
| leann-server | Local | - | - | ⛔ Pas migré | 5-Skip | ✅ SKIP |

## 🔧 Scripts de Migration

### Script 1 : Audit des secrets
```bash
#!/bin/bash
# scripts/audit-mcp-secrets.sh
# Compare Claude Desktop config vs Vault secrets

echo "=== MCP Servers with Secrets in Claude Desktop ==="
# Parse claude_desktop_config.json
# Extract servers with env.* keys
# Compare with Vault secrets

echo "=== Missing Secrets in Vault ==="
# List secrets to create
```

### Script 2 : Migration d'un serveur
```bash
#!/bin/bash
# scripts/migrate-mcp-server.sh <server-name>
# Migrates a single MCP server to Docker MCP

SERVER=$1
# 1. Check if secret needed
# 2. Configure Docker MCP
# 3. Test
# 4. Update Claude Desktop config
```

### Script 3 : Backup et rollback
```bash
#!/bin/bash
# scripts/backup-claude-config.sh
# Backup Claude Desktop config before migration

cp "$HOME/Library/Application Support/Claude/claude_desktop_config.json" \
   "$HOME/Library/Application Support/Claude/claude_desktop_config.backup.$(date +%Y%m%d-%H%M%S).json"
```

## 📈 Métriques de Succès

- ✅ **Aucun secret hardcodé** dans claude_desktop_config.json
- ✅ **Tous les secrets dans Vault** (datligent/mcp/shared/*)
- ✅ **Configuration Claude Desktop ≤ 5 entrées** (au lieu de 19)
- ✅ **Source unique : Docker MCP** pour tous les serveurs compatibles
- ✅ **Source unique : Vault** pour tous les secrets

## 🚀 Prochaines Étapes

1. **Créer les secrets manquants dans Vault**
   - context7
   - neo4j-memory

2. **Tester Docker MCP avec un serveur simple**
   - terraform (pas de secret)

3. **Migration du premier serveur avec secret**
   - brave-search

4. **Documenter le process**
   - Créer un playbook de migration

5. **Migration progressive**
   - 1 serveur par jour
   - Validation après chaque migration

---

**Créé le** : 2025-10-10
**Statut** : 📋 PLAN EN COURS
**Prochaine action** : Créer audit-mcp-secrets.sh
