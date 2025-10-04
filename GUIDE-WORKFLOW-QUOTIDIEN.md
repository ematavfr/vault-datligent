# 🎯 Guide de Workflow Quotidien - Vault MCP pour Outils IA

## 📖 Philosophie

Au lieu de stocker vos clés API en dur dans chaque configuration MCP, **centralisez-les dans Vault** et laissez vos outils IA les récupérer dynamiquement quand ils en ont besoin.

## 🔄 Workflow Standard

### Étape 1 : Stockez vos clés dans Vault (une seule fois)

```bash
# Ajouter votre clé DeepL
./scripts/add-mcp-secret.sh deepl api_key="votre-vraie-clé-deepl"

# Ajouter votre token GitHub
./scripts/add-mcp-secret.sh github token="ghp_votre_token_réel"

# Ajouter vos credentials Composio
./scripts/add-mcp-secret.sh composio \
  api_key="votre-clé-composio" \
  entity_id="votre-entity-id"

# Ajouter votre clé Anthropic
./scripts/add-mcp-secret.sh anthropic api_key="sk-ant-votre-clé"
```

### Étape 2 : Utilisez vos outils IA normalement

Vos outils IA (Claude Code, Cursor, etc.) peuvent maintenant récupérer les clés en temps réel.

## 💼 Cas d'Usage Quotidiens

### 🌐 Cas 1 : Configurer un nouveau serveur MCP

**Scénario** : Vous voulez utiliser le serveur MCP DeepL dans Claude Code

**Ancienne méthode (sans Vault)** :
1. Chercher votre clé DeepL dans vos notes/emails
2. La copier dans la configuration MCP
3. Risque : clé en clair dans le fichier de config

**Nouvelle méthode (avec Vault)** :

**Vous dites à Claude Code :**
```
"Configure le serveur MCP DeepL pour moi"
```

**Claude Code exécute automatiquement :**
1. *"Récupère ma clé API DeepL depuis Vault"*
2. Obtient la clé de manière sécurisée
3. Configure le serveur MCP avec la clé
4. Supprime la clé de la mémoire après usage

**Résultat** : Configuration sécurisée sans exposer votre clé !

---

### 🔧 Cas 2 : Utiliser une API dans un script

**Scénario** : Vous développez un script qui utilise l'API GitHub

**Vous dites à Claude Code :**
```
"Écris un script Python qui liste mes repos GitHub.
Utilise le token depuis Vault."
```

**Claude Code génère :**

```python
#!/usr/bin/env python3
import os
import subprocess
import json
import requests

# Récupérer le token depuis Vault via Claude
# Note: Claude a déjà récupéré le token de manière sécurisée

def get_github_token():
    """
    Cette fonction serait appelée par Claude pour récupérer
    le token depuis Vault de manière sécurisée
    """
    # Claude exécute: vault kv get -field=token datligent/mcp/shared/github
    return os.environ.get('GITHUB_TOKEN')

def list_repos():
    token = get_github_token()
    headers = {'Authorization': f'token {token}'}

    response = requests.get(
        'https://api.github.com/user/repos',
        headers=headers
    )

    if response.status_code == 200:
        repos = response.json()
        for repo in repos:
            print(f"📦 {repo['name']} - {repo['html_url']}")
    else:
        print(f"❌ Erreur: {response.status_code}")

if __name__ == '__main__':
    list_repos()
```

**Avantage** : Pas de token en dur dans le code !

---

### 🔄 Cas 3 : Rotation de clés API

**Scénario** : Vous devez changer votre clé OpenAI compromise

**Vous dites à Claude Code :**
```
"Ma clé OpenAI a été compromise.
Génère une nouvelle clé et mets à jour Vault."
```

**Claude Code :**
1. Vous guide pour générer une nouvelle clé sur OpenAI
2. *"Mets à jour le secret OpenAI dans Vault avec la nouvelle clé"*
3. Tous vos outils (Claude Code, Cursor, etc.) utilisent instantanément la nouvelle clé

**Commande manuelle alternative :**
```bash
./scripts/add-mcp-secret.sh openai api_key="sk-nouvelle-clé"
```

---

### 🔍 Cas 4 : Vérifier vos secrets disponibles

**Vous dites à Claude Code :**
```
"Quels secrets MCP sont disponibles dans Vault ?"
```

**Claude Code exécute :**
```bash
./scripts/list-mcp-secrets.sh
```

**Résultat affiché :**
```
🔐 Secrets MCP disponibles dans Vault

📋 Liste des services configurés:

📦 Service: deepl
   Path: datligent/mcp/shared/deepl
   Clés:
      • api_key: votre-cl...
   Metadata:
      • Version: 2
      • Créé: 2025-10-01T08:30:00Z

📦 Service: github
   Path: datligent/mcp/shared/github
   ...
```

---

### 🚀 Cas 5 : Partager une configuration entre outils

**Scénario** : Vous utilisez la même clé API Anthropic dans Claude Code et Cursor

**Une seule fois :**
```bash
./scripts/add-mcp-secret.sh anthropic api_key="sk-ant-votre-clé"
```

**Ensuite, dans Claude Code :**
```
"Récupère ma clé Anthropic depuis Vault pour configurer le MCP"
```

**Ensuite, dans Cursor :**
```
"Récupère ma clé Anthropic depuis Vault pour configurer le MCP"
```

**Résultat** : Les deux outils utilisent la même clé, stockée une seule fois !

---

### 🛠️ Cas 6 : Développer avec plusieurs environnements

**Scénario** : Vous avez des clés différentes pour dev/staging/prod

**Structure dans Vault :**
```bash
# Développement
./scripts/add-mcp-secret.sh stripe-dev api_key="sk_test_..."

# Staging
./scripts/add-mcp-secret.sh stripe-staging api_key="sk_test_staging_..."

# Production
./scripts/add-mcp-secret.sh stripe-prod api_key="sk_live_..."
```

**Usage :**
```
"Utilise la clé Stripe dev pour tester le paiement"
"Utilise la clé Stripe prod pour le déploiement"
```

---

## 📋 Workflows Spécifiques par Outil

### Claude Code

#### Configuration initiale
```
"Liste mes secrets MCP disponibles"
"Configure tous mes serveurs MCP avec les clés depuis Vault"
```

#### Usage quotidien
```
"Récupère ma clé DeepL et traduis ce texte en français"
"Utilise mon token GitHub pour créer un nouveau repo"
"Avec ma clé Composio, récupère mes emails Gmail"
```

### Cursor

#### Configuration
```
"Configure le serveur MCP Vault pour Cursor"
"Récupère tous mes secrets MCP depuis Vault"
```

#### Usage quotidien
```
"Utilise ma clé GitHub pour push ce code"
"Récupère ma clé OpenAI pour générer des tests"
```

### Gemini-CLI

```bash
# Configuration (une fois)
gemini "Configure MCP Vault avec le token depuis ~/vault-datligent/init-data/ai-tools-token.txt"

# Usage
gemini "Récupère ma clé DeepL depuis Vault"
gemini "Liste tous mes secrets MCP"
```

### Codex

```bash
# Configuration (une fois)
codex setup vault-mcp

# Usage
codex "Utilise mon token GitHub depuis Vault pour cloner ce repo"
```

---

## 🔐 Bonnes Pratiques de Sécurité

### ✅ À FAIRE

1. **Stockez les clés dans Vault dès leur création**
   ```bash
   ./scripts/add-mcp-secret.sh nouveau-service api_key="..."
   ```

2. **Utilisez des commandes naturelles pour récupérer les clés**
   ```
   "Récupère ma clé X depuis Vault"
   ```

3. **Ne hardcodez jamais les clés dans le code**
   ```python
   # ❌ MAUVAIS
   API_KEY = "sk-1234567890abcdef"

   # ✅ BON
   # Claude récupère depuis Vault au moment de l'exécution
   ```

4. **Rotez régulièrement vos secrets**
   ```bash
   # Tous les 90 jours
   ./scripts/add-mcp-secret.sh service api_key="nouvelle-clé"
   ```

5. **Auditez les accès**
   ```bash
   # Voir qui accède à quoi
   vault audit enable file file_path=/vault/logs/audit.log
   ```

### ❌ À ÉVITER

1. **Ne copiez pas les clés dans les messages de chat**
2. **Ne commitez jamais de clés dans Git**
3. **N'envoyez pas de clés par email/Slack**
4. **Ne stockez pas de clés en clair dans les fichiers de config**
5. **N'utilisez pas le token root pour les applications**

---

## 🎬 Scénarios Complets de Workflow

### Scénario A : Nouveau Projet avec APIs Multiples

**Objectif** : Créer un projet qui utilise GitHub, OpenAI et Stripe

**Étape 1 - Préparer les secrets (une fois)**
```bash
./scripts/add-mcp-secret.sh github token="ghp_..."
./scripts/add-mcp-secret.sh openai api_key="sk-..."
./scripts/add-mcp-secret.sh stripe-dev api_key="sk_test_..."
```

**Étape 2 - Développer avec Claude Code**
```
"Crée un projet Next.js qui :
1. Clone un template depuis GitHub (utilise mon token Vault)
2. Génère du contenu avec OpenAI (utilise ma clé Vault)
3. Intègre Stripe pour les paiements (utilise ma clé dev Vault)"
```

**Claude Code va :**
- Récupérer automatiquement les 3 clés depuis Vault
- Les utiliser dans le code de manière sécurisée
- Ne jamais les exposer en clair

**Étape 3 - Partager avec l'équipe**
Vos collègues ajoutent leurs propres clés dans leur Vault local et le code fonctionne immédiatement !

---

### Scénario B : Migration d'un Projet Existant

**Situation** : Vous avez un projet avec des clés en dur dans `.env`

**Fichier `.env` actuel :**
```bash
GITHUB_TOKEN=ghp_hardcoded_token_here
OPENAI_API_KEY=sk-hardcoded_key_here
STRIPE_KEY=sk_test_hardcoded
```

**Migration vers Vault :**

**Étape 1 - Importer dans Vault**
```bash
# Lire les clés depuis .env et les importer
source .env
./scripts/add-mcp-secret.sh github token="$GITHUB_TOKEN"
./scripts/add-mcp-secret.sh openai api_key="$OPENAI_API_KEY"
./scripts/add-mcp-secret.sh stripe-dev api_key="$STRIPE_KEY"
```

**Étape 2 - Modifier le code**

**Vous dites à Claude Code :**
```
"Modifie le projet pour utiliser Vault au lieu de .env :
1. Crée un script qui récupère les secrets depuis Vault
2. Remplace toutes les références à process.env par les secrets Vault
3. Supprime le fichier .env"
```

**Étape 3 - Documenter**
```
"Crée un README expliquant comment configurer Vault pour ce projet"
```

---

### Scénario C : Travail Multi-Outils

**Situation** : Vous alternez entre Claude Code, Cursor et terminal

**Matin - Claude Code**
```
"Liste mes secrets MCP"
"Utilise ma clé OpenAI pour générer des tests"
```

**Après-midi - Cursor**
```
"Récupère ma clé GitHub depuis Vault"
"Push le code avec authentification"
```

**Soir - Terminal direct**
```bash
source .env.vault
export VAULT_TOKEN="$VAULT_AI_TOOLS_TOKEN"
vault kv get datligent/mcp/shared/github
```

**Résultat** : Expérience fluide, mêmes clés partout !

---

## 🔄 Maintenance Régulière

### Hebdomadaire

```bash
# Vérifier les secrets disponibles
./scripts/list-mcp-secrets.sh

# Vérifier l'expiration du token
source .env.vault
export VAULT_TOKEN="$VAULT_AI_TOOLS_TOKEN"
vault token lookup | grep ttl
```

### Mensuelle

```bash
# Renouveler le token AI tools
vault token renew

# Auditer les accès
vault read sys/audit

# Sauvegarder Vault
docker exec vault-datligent vault operator raft snapshot save backup.snap
```

### Trimestrielle (90 jours)

```bash
# Rotation de tous les secrets
./scripts/add-mcp-secret.sh deepl api_key="nouvelle-clé-deepl"
./scripts/add-mcp-secret.sh github token="nouveau-token-github"
# ... autres services
```

---

## 📊 Comparaison Avant/Après

### ❌ AVANT (sans Vault)

```
📁 projet/
├── .env                    # ⚠️ Clés en clair
├── .env.local             # ⚠️ Clés en clair
├── config/
│   └── api-keys.json      # ⚠️ Clés en clair
└── .gitignore             # 🤞 Espère que .env est ignoré
```

**Problèmes :**
- ❌ Clés éparpillées dans plusieurs fichiers
- ❌ Risque de commit accidentel
- ❌ Difficile de partager avec l'équipe
- ❌ Pas d'audit des accès
- ❌ Rotation manuelle et fastidieuse

### ✅ APRÈS (avec Vault)

```
📁 projet/
├── .env.vault             # ✅ Juste l'adresse Vault + token
└── README.md              # ✅ Instructions Vault
```

**Avantages :**
- ✅ Une seule source de vérité
- ✅ Impossible de committer des secrets
- ✅ Partage sécurisé avec l'équipe
- ✅ Audit centralisé
- ✅ Rotation en une commande

---

## 🎯 Commandes à Connaître par Cœur

### Gestion des secrets
```bash
# Ajouter un secret
./scripts/add-mcp-secret.sh <service> key="value"

# Lister tous les secrets
./scripts/list-mcp-secrets.sh

# Voir un secret spécifique
vault kv get datligent/mcp/shared/<service>
```

### Depuis vos outils IA (langage naturel)
```
"Liste mes secrets MCP"
"Récupère ma clé API <service> depuis Vault"
"Mets à jour mon token <service> dans Vault"
"Crée un nouveau secret pour <service>"
```

### Maintenance Vault
```bash
# Statut
docker ps | grep vault-datligent

# Renouveler le token
vault token renew

# Backup
docker exec vault-datligent vault operator raft snapshot save backup.snap
```

---

## 💡 Astuces Pro

### Astuce 1 : Alias pratiques

Ajoutez à votre `~/.bashrc` ou `~/.zshrc` :

```bash
# Alias Vault
alias vlist='cd ~/vault-datligent && ./scripts/list-mcp-secrets.sh'
alias vadd='cd ~/vault-datligent && ./scripts/add-mcp-secret.sh'
alias venv='source ~/vault-datligent/.env.vault'

# Utilisation
vlist              # Lister les secrets
vadd service key="value"   # Ajouter un secret
venv               # Charger l'environnement Vault
```

### Astuce 2 : Templates de secrets

Créez des templates pour vos services communs :

```bash
# ~/vault-datligent/templates/add-stripe.sh
./scripts/add-mcp-secret.sh stripe-dev \
  api_key="$1" \
  publishable_key="$2" \
  webhook_secret="$3"
```

Usage :
```bash
~/vault-datligent/templates/add-stripe.sh "sk_test_..." "pk_test_..." "whsec_..."
```

### Astuce 3 : Vérification pre-commit

Créez un git hook qui vérifie qu'aucune clé n'est commitée :

```bash
# .git/hooks/pre-commit
#!/bin/bash

# Vérifier qu'aucune clé API n'est dans le commit
if git diff --cached | grep -E "(api_key|secret|token|password).*=.*['\"][A-Za-z0-9]{20,}"; then
    echo "❌ Détection de secret potentiel dans le commit!"
    echo "💡 Utilisez Vault: ./scripts/add-mcp-secret.sh"
    exit 1
fi
```

### Astuce 4 : Environnements multiples

```bash
# Structure pour dev/staging/prod
./scripts/add-mcp-secret.sh api-dev key="..."
./scripts/add-mcp-secret.sh api-staging key="..."
./scripts/add-mcp-secret.sh api-prod key="..."

# Variable d'environnement pour choisir
export ENV=dev
# Vos outils utilisent automatiquement api-$ENV
```

---

## 🆘 Dépannage Courant

### Problème : "Vault ne répond pas"

```bash
# Vérifier Vault
docker ps | grep vault-datligent

# Redémarrer si nécessaire
docker-compose -f docker-compose-simple.yml restart
```

### Problème : "Token expiré"

```bash
# Renouveler
source .env.vault
export VAULT_TOKEN="$VAULT_AI_TOOLS_TOKEN"
vault token renew

# Si trop tard, recréer
export VAULT_TOKEN="$VAULT_ROOT_TOKEN"
vault token create -policy=ai-tools-mcp-access -ttl=768h -renewable
```

### Problème : "Secret non trouvé"

```bash
# Vérifier le chemin exact
vault kv list datligent/mcp/shared

# Créer si manquant
./scripts/add-mcp-secret.sh service key="value"
```

### Problème : "Permission denied"

```bash
# Vérifier les permissions du token
vault token capabilities datligent/mcp/shared/service

# Vérifier la politique
vault policy read ai-tools-mcp-access
```

---

## 📚 Ressources Complémentaires

- **Guide de démarrage** : `QUICKSTART.md`
- **Documentation complète** : `AI-TOOLS-VAULT-SETUP.md`
- **Scripts disponibles** : `scripts/`
- **Interface Web Vault** : http://localhost:8200/ui/

---

## ✨ En Résumé

**Principe clé** :
> Stockez une fois dans Vault, utilisez partout avec des commandes naturelles

**Workflow quotidien** :
1. 📦 Stockez vos clés dans Vault (une fois)
2. 💬 Demandez à vos outils IA de les récupérer (en langage naturel)
3. 🔒 Vos clés restent sécurisées et centralisées
4. 🔄 Rotez facilement quand nécessaire

**Bénéfice final** :
> Plus de clés en dur, plus de risque de fuite, workflow fluide entre tous vos outils IA !

---

*Guide créé le 2025-10-01 pour l'écosystème Datligent*
