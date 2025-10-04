# 🔐 Guide de Migration : Configuration MCP vers Vault

## 📋 Résumé

Ce guide documente la migration de toutes vos clés API MCP de la configuration Claude Desktop vers HashiCorp Vault pour une gestion centralisée et sécurisée.

## ✅ Ce qui a été fait

### 1. Migration des secrets dans Vault

**9 services migrés** avec toutes leurs clés API :

| Service | Clés stockées | Statut |
|---------|---------------|--------|
| 🔍 **Brave Search** | `api_key` | ✅ Migré |
| 📊 **Airtable** | `api_key` | ✅ Migré |
| 🐙 **GitHub** | `personal_access_token` | ✅ Migré |
| 🔎 **Tavily** | `api_key` | ✅ Migré |
| ☁️ **AWS** | `access_key_id`, `secret_access_key`, `default_region` | ✅ Migré |
| 🌐 **DeepL** | `api_key` | ✅ Migré |
| 🦊 **GitLab** | `personal_access_token`, `api_url` | ✅ Migré |
| 🤖 **OpenAI** | `api_key` | ✅ Template |
| 🔧 **Composio** | `api_key`, `entity_id` | ✅ Template |

**Path Vault** : `datligent/mcp/shared/<service>`

### 2. Serveur MCP Vault ajouté

Un nouveau serveur MCP `vault-mcp` a été ajouté à la configuration pour permettre l'accès aux secrets via des commandes naturelles.

### 3. Serveur Terraform MCP ajouté

Le serveur MCP Terraform a été ajouté à la configuration (remplace `hcp-terraform`).

### 4. Scripts créés

- ✅ `scripts/load-mcp-env.sh` - Charge les variables d'environnement depuis Vault
- ✅ `scripts/install-vault-mcp-config.sh` - Script d'installation automatique
- ✅ Configuration template créée : `claude_desktop_config_vault.json`

## 🚀 Installation

### Étape 1 : Vérifier que Vault est démarré

```bash
docker ps | grep vault-datligent
```

Si Vault n'est pas démarré :
```bash
cd ~/vault-datligent
docker-compose -f docker-compose-simple.yml up -d
```

### Étape 2 : Vérifier les secrets

```bash
cd ~/vault-datligent
./scripts/list-mcp-secrets.sh
```

Vous devriez voir 9 services configurés.

### Étape 3 : Installer la nouvelle configuration

```bash
cd ~/vault-datligent
./scripts/install-vault-mcp-config.sh
```

Ce script va :
1. ✅ Sauvegarder votre configuration actuelle
2. ✅ Vérifier que Vault est accessible
3. ✅ Vérifier que tous les secrets sont présents
4. ✅ Générer une nouvelle configuration avec les valeurs depuis Vault
5. ✅ Installer la configuration pour Claude Desktop

### Étape 4 : Redémarrer Claude Desktop

**Important** : Vous devez redémarrer complètement Claude Desktop pour que les changements prennent effet.

1. Quittez Claude Desktop (Cmd+Q)
2. Relancez Claude Desktop

### Étape 5 : Vérifier que tout fonctionne

Une fois Claude Desktop redémarré, testez :

```
"Liste tous mes serveurs MCP"
"Récupère ma clé API DeepL depuis Vault"
```

## 📊 Comparaison Avant/Après

### ❌ AVANT

**Fichier** : `~/Library/Application Support/Claude/claude_desktop_config.json`

```json
{
  "brave-search": {
    "env": {
      "BRAVE_API_KEY": "BSAFu1gQpqZTWGGiAdj-ah-1GxjEeUj"  ❌ Clé en clair
    }
  },
  "github": {
    "env": {
      "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxx"  ❌ Clé en clair
    }
  }
  // ... 7 autres services avec clés en clair
}
```

**Problèmes :**
- ❌ 9 clés API en clair dans le fichier
- ❌ Risque de fuite lors de partage de config
- ❌ Aucun audit des accès
- ❌ Rotation manuelle fastidieuse
- ❌ Difficile de synchroniser entre machines

### ✅ APRÈS

**Secrets dans Vault** : `datligent/mcp/shared/*`

**Fichier de configuration** : Généré automatiquement depuis Vault

```json
{
  "vault-mcp": {
    "command": "docker",
    "args": [...],
    "env": {
      "VAULT_ADDR": "http://host.docker.internal:8200",
      "VAULT_TOKEN": "hvs.CAE..."  // Token d'accès limité
    }
  },
  "brave-search": {
    "env": {
      "BRAVE_API_KEY": "<récupéré depuis Vault>"  ✅ Valeur injectée au démarrage
    }
  }
}
```

**Avantages :**
- ✅ Secrets centralisés dans Vault
- ✅ Une seule source de vérité
- ✅ Audit centralisé des accès
- ✅ Rotation simplifiée (une commande)
- ✅ Synchronisation facile entre machines
- ✅ Backup et versioning des secrets
- ✅ Accès via commandes naturelles

## 🔄 Workflow de mise à jour

### Mettre à jour un secret

```bash
cd ~/vault-datligent

# Méthode 1 : Script rapide
./scripts/add-mcp-secret.sh github personal_access_token="nouveau_token"

# Méthode 2 : Vault CLI
source .env.vault
vault kv put datligent/mcp/shared/github personal_access_token="nouveau_token"
```

### Régénérer la configuration MCP

Après avoir mis à jour un secret, régénérez la configuration :

```bash
./scripts/install-vault-mcp-config.sh
```

Puis redémarrez Claude Desktop.

### Ajouter un nouveau service

```bash
# Ajouter le secret dans Vault
./scripts/add-mcp-secret.sh nouveau-service api_key="clé_api" other_field="valeur"

# Modifier le fichier claude_desktop_config_vault.json pour ajouter le serveur MCP
# Puis régénérer
./scripts/install-vault-mcp-config.sh
```

## 🔍 Commandes utiles

### Lister tous les secrets

```bash
cd ~/vault-datligent
./scripts/list-mcp-secrets.sh
```

### Voir un secret spécifique

```bash
source .env.vault
vault kv get datligent/mcp/shared/github
```

### Voir seulement un champ

```bash
source .env.vault
vault kv get -field=personal_access_token datligent/mcp/shared/github
```

### Historique des versions d'un secret

```bash
source .env.vault
vault kv metadata get datligent/mcp/shared/github
```

### Restaurer une version précédente

```bash
source .env.vault
vault kv get -version=1 datligent/mcp/shared/github
vault kv rollback -version=1 datligent/mcp/shared/github
```

## 🆘 Dépannage

### Problème : "Vault n'est pas accessible"

```bash
# Vérifier Vault
docker ps | grep vault-datligent

# Démarrer Vault si nécessaire
cd ~/vault-datligent
docker-compose -f docker-compose-simple.yml up -d

# Vérifier la connectivité
curl http://localhost:8200/v1/sys/health
```

### Problème : "Secret non trouvé"

```bash
# Lister les secrets disponibles
source ~/vault-datligent/.env.vault
vault kv list datligent/mcp/shared

# Ajouter le secret manquant
cd ~/vault-datligent
./scripts/add-mcp-secret.sh service key="value"
```

### Problème : "Les serveurs MCP ne fonctionnent pas après migration"

1. Vérifiez que les secrets sont bien dans Vault :
   ```bash
   ./scripts/list-mcp-secrets.sh
   ```

2. Régénérez la configuration :
   ```bash
   ./scripts/install-vault-mcp-config.sh
   ```

3. Redémarrez complètement Claude Desktop (Cmd+Q puis relancer)

### Problème : "Je veux revenir à l'ancienne configuration"

Toutes vos configurations sont sauvegardées automatiquement :

```bash
# Lister les backups
ls -la ~/Library/Application\ Support/Claude/claude_desktop_config.json.backup.*

# Restaurer un backup (remplacez par la date voulue)
cp ~/Library/Application\ Support/Claude/claude_desktop_config.json.backup.20251001_100000 \
   ~/Library/Application\ Support/Claude/claude_desktop_config.json

# Redémarrer Claude Desktop
```

## 📈 Avantages de la migration

### Sécurité

- ✅ **Secrets hors du fichier de config** - Plus de risque de commit accidentel
- ✅ **Contrôle d'accès granulaire** - Politique Vault dédiée
- ✅ **Audit trail** - Tous les accès sont loggés
- ✅ **Chiffrement at-rest** - Secrets chiffrés dans Vault
- ✅ **Token avec TTL** - Expiration et renouvellement automatiques

### Productivité

- ✅ **Source unique** - Un seul endroit pour gérer toutes les clés
- ✅ **Rotation rapide** - Une commande pour changer une clé
- ✅ **Synchronisation facile** - Même config sur toutes vos machines
- ✅ **Versioning** - Historique et rollback des secrets
- ✅ **Commandes naturelles** - "Récupère ma clé X depuis Vault"

### Maintenance

- ✅ **Backup automatique** - Sauvegarde des configurations
- ✅ **Scripts automatisés** - Régénération de config en une commande
- ✅ **Documentation vivante** - Secrets documentés dans Vault
- ✅ **Migration vers autres outils** - Cursor, Gemini-CLI utilisent les mêmes secrets

## 🎯 Prochaines étapes recommandées

### 1. Mettre à jour les templates

Remplacez les valeurs template par vos vraies clés :

```bash
# OpenAI
./scripts/add-mcp-secret.sh openai api_key="sk-votre-vraie-clé"

# Composio
./scripts/add-mcp-secret.sh composio \
  api_key="votre-clé-composio" \
  entity_id="votre-entity-id"
```

### 2. Configurer vos autres outils

Si vous utilisez Cursor, Gemini-CLI ou Codex :

```bash
./scripts/configure-ai-tools.sh
```

### 3. Mettre en place une rotation régulière

Créez un rappel pour :
- ✅ Renouveler les tokens tous les 30 jours
- ✅ Changer les clés API tous les 90 jours
- ✅ Auditer les accès mensuellement

### 4. Documenter vos secrets

Ajoutez des descriptions claires à chaque secret :

```bash
vault kv put datligent/mcp/shared/service \
  api_key="..." \
  description="Clé API pour l'environnement de production" \
  owner="votre-nom" \
  expires="2025-12-31"
```

### 5. Configurer les alertes

Mettez en place des alertes pour :
- ✅ Expiration imminente des tokens
- ✅ Tentatives d'accès non autorisées
- ✅ Vault indisponible

## 📚 Ressources

- **Guide de démarrage rapide** : `QUICKSTART.md`
- **Workflow quotidien** : `GUIDE-WORKFLOW-QUOTIDIEN.md`
- **Configuration complète** : `AI-TOOLS-VAULT-SETUP.md`
- **Scripts utilitaires** : `scripts/`

## 🔐 Sécurité

### Fichiers à protéger

Ces fichiers contiennent des informations sensibles :

```bash
# Token d'accès
~/vault-datligent/init-data/ai-tools-token.txt

# Configuration avec secrets
~/Library/Application Support/Claude/claude_desktop_config.json

# Backups
~/Library/Application Support/Claude/claude_desktop_config.json.backup.*
```

### Bonnes pratiques

1. ✅ **Ne commitez jamais** les fichiers ci-dessus dans Git
2. ✅ **Chiffrez vos backups** si vous les stockez dans le cloud
3. ✅ **Utilisez le token AI tools** au lieu du token root
4. ✅ **Renouvelez régulièrement** vos tokens et secrets
5. ✅ **Auditez les accès** périodiquement

## ✨ Résumé

**Avant la migration :**
- 9 clés API en clair dans la configuration
- Gestion manuelle et dispersée
- Risques de sécurité élevés

**Après la migration :**
- Tous les secrets dans Vault
- Gestion centralisée et sécurisée
- Rotation simplifiée en une commande
- Accès via commandes naturelles
- Configuration générée automatiquement

**Commande magique pour tout mettre à jour :**
```bash
# 1. Mettre à jour un secret
./scripts/add-mcp-secret.sh service key="nouvelle-valeur"

# 2. Régénérer la config
./scripts/install-vault-mcp-config.sh

# 3. Redémarrer Claude Desktop
```

---

**Migration effectuée le** : 2025-10-01
**Dernière mise à jour** : 2025-10-01
**Secrets migrés** : 9 services
**Statut** : ✅ Terminé avec succès
