# 🚀 Quick Start - Vault MCP pour Outils IA

## ✅ Configuration terminée !

Votre infrastructure Vault est **prête à l'emploi** pour tous vos outils IA.

## 🎯 Ce qui a été configuré

✅ **Serveur Vault** démarré sur http://localhost:8200
✅ **Structure de secrets MCP** créée dans `datligent/mcp/shared/`
✅ **Politique d'accès** `ai-tools-mcp-access` configurée
✅ **Token partagé** généré pour tous vos outils IA
✅ **Claude Code** configuré automatiquement
✅ **Scripts utilitaires** créés pour faciliter la gestion

## 🔑 Token d'accès

Votre token d'accès partagé pour tous les outils IA :

```
YOUR_VAULT_TOKEN_HERE
```

**⚠️ Gardez ce token secret !**

## 📦 Secrets disponibles

4 services sont pré-configurés avec des templates :

- 🌐 **DeepL** - API de traduction
- 🐙 **GitHub** - Token d'accès personnel
- 🔧 **Composio** - Credentials API
- 🤖 **OpenAI** - Clé API

## 🎬 Utilisation immédiate

### Depuis Claude Code (déjà configuré ✅)

Vous pouvez maintenant utiliser des commandes naturelles :

```
"Récupère ma clé API DeepL depuis Vault"
"Affiche tous mes secrets MCP"
"Crée un nouveau secret pour Anthropic avec la clé sk-ant-..."
```

### Configurer vos autres outils

```bash
# Configuration automatique de tous vos outils
./scripts/configure-ai-tools.sh
```

**Ou manuellement :**

**Cursor** : Paramètres → MCP → Ajouter la config du fichier `AI-TOOLS-VAULT-SETUP.md`
**Gemini-CLI** : Créer `~/.config/gemini-cli/mcp.json` avec la config
**Codex** : Créer `~/.codex/mcp-servers.json` avec la config

Voir le guide complet : `AI-TOOLS-VAULT-SETUP.md`

## 🛠️ Scripts utilitaires

### Ajouter un secret

```bash
# Ajouter une clé API
./scripts/add-mcp-secret.sh anthropic api_key="sk-ant-xyz123..."

# Ajouter plusieurs valeurs
./scripts/add-mcp-secret.sh slack bot_token="xoxb-..." app_token="xapp-..."
```

### Lister les secrets

```bash
# Tous les secrets
./scripts/list-mcp-secrets.sh

# Un service spécifique
./scripts/list-mcp-secrets.sh deepl
```

### Configurer les outils IA

```bash
# Configurer automatiquement tous vos outils
./scripts/configure-ai-tools.sh
```

## 📖 Commandes Vault CLI

```bash
# Charger l'environnement
source .env.vault

# Lister les secrets
vault kv list datligent/mcp/shared

# Lire un secret
vault kv get datligent/mcp/shared/deepl

# Ajouter/Modifier un secret
vault kv put datligent/mcp/shared/anthropic api_key="sk-ant-..."

# Supprimer un secret
vault kv delete datligent/mcp/shared/anthropic
```

## 🔄 Maintenance

### Renouveler le token (avant expiration dans 32 jours)

```bash
source .env.vault
export VAULT_TOKEN="$VAULT_AI_TOOLS_TOKEN"
vault token renew
```

### Vérifier le statut

```bash
# Vault
docker ps | grep vault-datligent

# MCP
claude mcp list | grep vault-mcp
```

### Démarrer/Arrêter Vault

```bash
# Démarrer
docker-compose -f docker-compose-simple.yml up -d

# Arrêter
docker-compose -f docker-compose-simple.yml down
```

## 📚 Documentation complète

- **Guide complet** : `AI-TOOLS-VAULT-SETUP.md`
- **Cas d'usage MCP** : `mcp-vault-use-cases.md`
- **README principal** : `README.md`

## 💡 Exemples d'utilisation

### Ajouter vos vraies clés API

Remplacez les templates par vos vraies clés :

```bash
# DeepL
./scripts/add-mcp-secret.sh deepl api_key="votre-vraie-clé-deepl"

# GitHub
./scripts/add-mcp-secret.sh github token="ghp_votre_token_github"

# Composio
./scripts/add-mcp-secret.sh composio \
  api_key="votre-clé-composio" \
  entity_id="votre-entity-id"

# OpenAI
./scripts/add-mcp-secret.sh openai api_key="sk-votre-clé-openai"

# Anthropic (nouveau)
./scripts/add-mcp-secret.sh anthropic api_key="sk-ant-votre-clé"
```

### Utilisation depuis les outils IA

Une fois configurés, tous vos outils IA (Claude Code, Cursor, etc.) peuvent :

```
# Récupérer des secrets
"Donne-moi ma clé API DeepL"
"Quel est mon token GitHub ?"

# Lister des secrets
"Liste tous mes secrets MCP"
"Affiche les services configurés dans Vault"

# Créer/Modifier des secrets
"Ajoute une nouvelle clé API Stripe avec la valeur sk_test_..."
"Mets à jour mon token GitHub"

# Rotation de secrets
"Change ma clé OpenAI"
```

## 🆘 Besoin d'aide ?

### Le MCP ne se connecte pas

```bash
# Vérifier Vault
curl http://localhost:8200/v1/sys/health

# Vérifier le token
source .env.vault
export VAULT_TOKEN="$VAULT_AI_TOOLS_TOKEN"
vault token lookup
```

### Secrets non accessibles

```bash
# Vérifier les permissions
vault token capabilities datligent/mcp/shared/deepl

# Vérifier la politique
vault policy read ai-tools-mcp-access
```

## 🎉 Vous êtes prêt !

Tous vos outils IA peuvent maintenant accéder de manière centralisée et sécurisée à vos clés API via Vault.

**Prochaines étapes suggérées :**

1. ✅ Remplacer les templates par vos vraies clés API
2. ✅ Configurer vos autres outils (Cursor, Gemini-CLI, Codex)
3. ✅ Tester l'accès depuis chaque outil
4. ✅ Mettre en place une rotation régulière des secrets

**Profitez de votre nouvelle infrastructure de gestion de secrets ! 🚀**
