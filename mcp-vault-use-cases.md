# Documentation MCP Vault pour l'écosystème Datligent

## 🚀 Vue d'ensemble

Le serveur MCP (Model Context Protocol) Vault permet d'interagir avec HashiCorp Vault via des commandes naturelles au lieu de commandes techniques complexes. Cette intégration transforme la gestion des secrets de l'infrastructure Datligent en conversations intuitives.

## 📋 Configuration actuelle

### Serveur MCP installé
- **Nom** : `vault-mcp` (ashgw/vault-mcp)
- **Type** : Docker container
- **Connexion** : http://localhost:8200
- **Token** : datligent-root-token

### Fonctionnalités disponibles
- 🔐 **secret_create/read/delete** - Gestion CRUD des secrets
- 📜 **policy_create** - Création de politiques d'accès
- 📊 **Resources** - `vault://secrets` et `vault://policies`

## 🔧 Installation

Le serveur a été installé avec la commande :
```bash
claude mcp add-json vault-mcp '{
  "command": "docker",
  "args": [
    "run",
    "-i",
    "--rm",
    "-e",
    "VAULT_ADDR=http://localhost:8200",
    "-e",
    "VAULT_TOKEN=datligent-root-token",
    "ashgw/vault-mcp:latest"
  ]
}'
```

## 📖 Exemples pratiques d'utilisation

### 1. Consultation des secrets existants

**Avant (commande technique) :**
```bash
vault kv list datligent/
vault kv get datligent/backstage/auth
```

**Maintenant (commande naturelle) :**
```
"Liste tous les secrets disponibles dans Vault pour l'écosystème Datligent"
"Récupère le secret d'authentification de Backstage depuis Vault"
```

### 2. Gestion des secrets Backstage

**Consultation :**
```
"Quels sont les paramètres de base de données pour Backstage ?"
"Affiche le token GitHub configuré pour Backstage"
```

**Modification :**
```
"Mets à jour le token GitHub de Backstage avec cette nouvelle valeur"
"Change le mot de passe de la base de données Backstage"
```

### 3. Gestion des secrets Gitea

**Consultation :**
```
"Récupère les credentials admin de Gitea"
"Affiche la configuration de base de données Gitea"
```

**Modification :**
```
"Génère un nouveau mot de passe sécurisé pour l'admin Gitea"
"Mets à jour le secret JWT de Gitea"
```

### 4. Gestion des secrets LDAP

**Consultation :**
```
"Affiche les paramètres de connexion LDAP admin"
"Récupère le bind DN pour LDAP readonly"
```

**Modification :**
```
"Génère un nouveau mot de passe pour l'admin LDAP"
"Crée un nouveau compte de service LDAP"
```

### 5. Gestion des politiques d'accès

**Création de politiques :**
```
"Crée une politique Vault qui donne accès en lecture seule aux secrets Gitea"
"Génère une politique pour permettre à Backstage d'accéder à ses secrets"
```

**Consultation des politiques :**
```
"Liste toutes les politiques Vault configurées"
"Affiche les permissions de la politique backstage-policy"
```

### 6. Workflows automatisés

**Déploiement d'environnement :**
```
"Configure les secrets nécessaires pour déployer un nouvel environnement Backstage"
```
→ Actions automatiques :
- Lecture des secrets templates
- Génération de nouveaux secrets
- Application des politiques appropriées
- Création des tokens d'application

**Rotation de secrets :**
```
"Effectue une rotation des mots de passe pour tous les services de l'infrastructure"
```
→ Actions automatiques :
- Génération de nouveaux mots de passe sécurisés
- Mise à jour dans Vault
- Notification des services concernés

### 7. Monitoring et maintenance

**Vérification de santé :**
```
"Vérifie l'état de santé de tous les secrets Datligent"
"Liste les secrets qui n'ont pas été mis à jour depuis 90 jours"
```

**Audit et sécurité :**
```
"Affiche l'historique des accès aux secrets Backstage"
"Liste tous les tokens d'application créés ce mois"
```

## 🏗️ Structure des secrets Datligent

### Secrets Backstage
- `datligent/backstage/auth` - Clés d'authentification backend
- `datligent/backstage/database` - Configuration base de données
- `datligent/backstage/github` - Tokens et configuration GitHub

### Secrets Gitea
- `datligent/gitea/admin` - Credentials administrateur
- `datligent/gitea/database` - Configuration base de données
- `datligent/gitea/jwt` - Secrets JWT

### Secrets LDAP
- `datligent/ldap/admin` - Compte administrateur
- `datligent/ldap/readonly` - Compte lecture seule

### Secrets d'infrastructure
- `infrastructure/ssl/certificates` - Certificats SSL/TLS
- `infrastructure/monitoring` - Configuration monitoring

## 🛡️ Politiques de sécurité

### Politiques configurées
- **backstage-policy** - Accès aux secrets Backstage + lecture infrastructure
- **gitea-policy** - Accès aux secrets Gitea + lecture SSL
- **ldap-policy** - Accès complet aux secrets LDAP

### Tokens d'application
- **Backstage token** - TTL: 8760h (1 an)
- **Gitea token** - TTL: 8760h (1 an)

## 🚀 Avantages de l'approche MCP

### Simplicité d'usage
- **Avant** : Mémoriser les commandes `vault kv get/put/list`
- **Maintenant** : Conversations naturelles

### Automatisation intelligente
- **Avant** : Scripts bash complexes pour les workflows
- **Maintenant** : Instructions en langage naturel

### Sécurité renforcée
- **Avant** : Risque d'erreurs dans les commandes CLI
- **Maintenant** : Validation automatique des opérations

### Intégration écosystème
- **Avant** : Gestion manuelle des interdépendances
- **Maintenant** : Compréhension contextuelle des services

## 🔍 Vérification et diagnostic

### Statut du serveur MCP
```bash
claude mcp list
# Devrait afficher vault-mcp avec statut de connexion
```

### Test de connectivité Vault
```bash
source .env.vault
vault status
# Vérifie que Vault est accessible
```

### Logs de débogage
```bash
docker logs vault-datligent
# En cas de problèmes de connectivité
```

## 📚 Ressources complémentaires

- **Interface Web Vault** : http://localhost:8080/ui/
- **API Vault** : http://localhost:8200/v1/
- **Scripts de configuration** : `./scripts/setup-datligent-secrets.sh`
- **Exemples d'usage** : `./examples/practical-usage.md`
- **Commandes de référence** : `./scripts/vault-commands.sh`

## ⚡ Actions suivantes recommandées

1. **Tester les cas d'usage** avec des commandes naturelles
2. **Documenter les workflows spécifiques** à votre organisation
3. **Configurer des alertes** pour la rotation des secrets
4. **Intégrer avec CI/CD** pour le déploiement automatisé

---

*Cette documentation évolue avec l'usage du serveur MCP Vault dans l'écosystème Datligent.*