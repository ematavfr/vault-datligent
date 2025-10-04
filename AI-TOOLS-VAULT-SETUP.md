# Configuration Vault pour Outils IA Multi-Plateformes

## 🎯 Objectif

Permettre à **tous vos outils IA** (Claude Code, Cursor, Gemini-CLI, Codex, etc.) d'accéder de manière centralisée et sécurisée aux clés API et secrets via HashiCorp Vault avec le protocole MCP (Model Context Protocol).

## ✅ Configuration complétée

### 1. Infrastructure Vault

- **Serveur Vault** : http://localhost:8200
- **Mode** : Dev (simple instance)
- **Statut** : ✅ En cours d'exécution

```bash
# Vérifier le statut
docker ps | grep vault-datligent
```

### 2. Structure des secrets

```
datligent/mcp/
├── shared/              # Secrets partagés entre tous les outils IA
│   ├── deepl           # Clé API DeepL
│   ├── github          # Token GitHub
│   ├── composio        # Credentials Composio
│   └── openai          # Clé API OpenAI
├── claude-code/        # Secrets spécifiques à Claude Code (à créer si besoin)
├── cursor/             # Secrets spécifiques à Cursor (à créer si besoin)
├── gemini-cli/         # Secrets spécifiques à Gemini-CLI (à créer si besoin)
└── codex/              # Secrets spécifiques à Codex (à créer si besoin)
```

### 3. Politique d'accès unifiée

**Nom** : `ai-tools-mcp-access`

**Permissions** :
- ✅ Accès complet (CRUD) aux secrets partagés `datligent/mcp/shared/*`
- ✅ Lecture de tous les secrets spécifiques `datligent/mcp/+/*`
- ✅ Renouvellement automatique du token
- ✅ Consultation des métadonnées

**Fichier de politique** : `policies/ai-tools-mcp-access.hcl`

### 4. Token d'accès partagé (Option A)

**Token** : `hvs.YOUR_VAULT_TOKEN_HERE`

**Caractéristiques** :
- Display name : `ai-tools-unified-access`
- TTL : 768h (32 jours)
- Renouvelable : ✅ Oui
- Politique : `ai-tools-mcp-access`

**Stockage sécurisé** : `init-data/ai-tools-token.txt`

⚠️ **Important** : Ce token est partagé par tous vos outils IA. Gardez-le secret !

## 🔧 Configuration par outil

### Claude Code

**Statut** : ✅ Configuré automatiquement

```bash
# Vérifier la configuration
claude mcp list | grep vault-mcp
```

**Configuration MCP** :
```json
{
  "command": "docker",
  "args": [
    "run", "-i", "--rm",
    "-e", "VAULT_ADDR=http://host.docker.internal:8200",
    "-e", "VAULT_TOKEN=YOUR_VAULT_TOKEN_HERE",
    "ashgw/vault-mcp:latest"
  ]
}
```

### Cursor

**Configuration manuelle requise** :

1. Ouvrir les paramètres Cursor
2. Naviguer vers la section MCP
3. Ajouter la configuration suivante :

```json
{
  "vault": {
    "command": "docker",
    "args": [
      "run", "-i", "--rm",
      "-e", "VAULT_ADDR=http://host.docker.internal:8200",
      "-e", "VAULT_TOKEN=YOUR_VAULT_TOKEN_HERE",
      "ashgw/vault-mcp:latest"
    ]
  }
}
```

**Ou utiliser le script** :
```bash
./scripts/configure-ai-tools.sh
```

### Gemini-CLI

**Fichier de configuration** : `~/.config/gemini-cli/mcp.json`

Créer ou modifier le fichier avec :
```json
{
  "servers": {
    "vault": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-e", "VAULT_ADDR=http://host.docker.internal:8200",
        "-e", "VAULT_TOKEN=YOUR_VAULT_TOKEN_HERE",
        "ashgw/vault-mcp:latest"
      ]
    }
  }
}
```

### Codex

**Fichier de configuration** : `~/.codex/mcp-servers.json`

Créer ou modifier le fichier avec :
```json
{
  "vault-mcp": {
    "command": "docker",
    "args": [
      "run", "-i", "--rm",
      "-e", "VAULT_ADDR=http://host.docker.internal:8200",
      "-e", "VAULT_TOKEN=YOUR_VAULT_TOKEN_HERE",
      "ashgw/vault-mcp:latest"
    ]
  }
}
```

## 📖 Utilisation

### Commandes naturelles disponibles

Tous vos outils IA peuvent maintenant utiliser des commandes en langage naturel :

**Consultation de secrets :**
```
"Récupère ma clé API DeepL depuis Vault"
"Affiche tous les tokens GitHub disponibles"
"Quels sont mes credentials Composio ?"
"Montre-moi la clé OpenAI configurée"
```

**Création de secrets :**
```
"Crée un nouveau secret pour l'API Composio avec la clé xyz123"
"Ajoute un token GitHub pour mon projet personnel"
"Stocke ma nouvelle clé DeepL dans Vault"
```

**Modification de secrets :**
```
"Mets à jour ma clé API OpenAI"
"Change le token GitHub actuel"
"Rotate tous les secrets de plus de 90 jours"
```

**Liste et recherche :**
```
"Liste tous les secrets disponibles"
"Affiche les secrets partagés"
"Recherche les clés API expirées"
```

### Commandes CLI directes

Si vous préférez utiliser la CLI Vault directement :

```bash
# Configurer l'environnement
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="YOUR_VAULT_TOKEN_HERE"

# Lister les secrets
vault kv list datligent/mcp/shared

# Lire un secret
vault kv get datligent/mcp/shared/deepl

# Créer/Modifier un secret
vault kv put datligent/mcp/shared/deepl api_key="votre-clé-ici"

# Supprimer un secret
vault kv delete datligent/mcp/shared/deepl
```

## 🔄 Renouvellement du token

Le token expire après 768h (32 jours) mais est **renouvelable** :

```bash
# Renouveler le token
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="YOUR_VAULT_TOKEN_HERE"
vault token renew

# Vérifier le TTL restant
vault token lookup
```

## 🛡️ Sécurité

### Bonnes pratiques

1. **Ne partagez jamais le token** publiquement (GitHub, Slack, etc.)
2. **Renouvelez régulièrement** le token avant expiration
3. **Utilisez des secrets différents** pour production et développement
4. **Auditez les accès** régulièrement

### Révocation d'urgence

En cas de compromission du token :

```bash
# Révoquer le token compromis
vault token revoke YOUR_VAULT_TOKEN_HERE

# Générer un nouveau token
vault token create \
  -policy=ai-tools-mcp-access \
  -display-name="ai-tools-unified-access-new" \
  -ttl=768h \
  -renewable

# Mettre à jour la configuration de tous vos outils
./scripts/configure-ai-tools.sh
```

## 🚀 Script de configuration automatique

Un script est fourni pour configurer automatiquement tous vos outils :

```bash
./scripts/configure-ai-tools.sh
```

Ce script :
- ✅ Charge le token depuis `init-data/ai-tools-token.txt`
- ✅ Configure Claude Code automatiquement
- ✅ Crée les fichiers de configuration pour Cursor, Gemini-CLI et Codex
- ✅ Affiche un résumé de la configuration

## 📁 Fichiers importants

```
vault-datligent/
├── init-data/
│   └── ai-tools-token.txt              # Token d'accès partagé
├── policies/
│   └── ai-tools-mcp-access.hcl         # Politique d'accès
├── scripts/
│   └── configure-ai-tools.sh           # Script de configuration auto
├── AI-TOOLS-VAULT-SETUP.md             # Cette documentation
└── .env.vault                          # Variables d'environnement Vault
```

## 🔍 Dépannage

### Le serveur MCP ne se connecte pas

```bash
# Vérifier que Vault est démarré
docker ps | grep vault-datligent

# Vérifier la connectivité
curl http://localhost:8200/v1/sys/health

# Tester le token
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="YOUR_VAULT_TOKEN_HERE"
vault token lookup
```

### Les secrets ne sont pas accessibles

```bash
# Vérifier les permissions du token
vault token capabilities datligent/mcp/shared/deepl

# Vérifier la politique
vault policy read ai-tools-mcp-access
```

### Docker ne peut pas se connecter à Vault

Sur macOS, utilisez `host.docker.internal` au lieu de `localhost` dans la configuration MCP :
```
VAULT_ADDR=http://host.docker.internal:8200
```

## 📚 Ressources

- **Interface Web Vault** : http://localhost:8200/ui/
- **Documentation Vault** : https://www.vaultproject.io/docs
- **Documentation MCP** : https://github.com/ashgw/vault-mcp
- **Serveur MCP utilisé** : `ashgw/vault-mcp:latest`

## ✨ Avantages de cette configuration

### 🔐 Sécurité centralisée
- Un seul point de gestion pour toutes les clés API
- Audit centralisé des accès
- Révocation instantanée en cas de problème

### 🚀 Simplicité d'usage
- Commandes en langage naturel
- Pas besoin de mémoriser où sont les clés
- Partage automatique entre tous vos outils

### 🔄 Maintenance facilitée
- Rotation des secrets simplifiée
- Renouvellement automatique des tokens
- Configuration unifiée pour tous les outils

### 🎯 Productivité améliorée
- Plus besoin de chercher les clés API
- Tous vos outils ont accès aux mêmes secrets
- Workflow unifié entre Claude Code, Cursor, etc.

---

**Configuration réalisée le** : 2025-10-01
**Dernière mise à jour** : 2025-10-01
