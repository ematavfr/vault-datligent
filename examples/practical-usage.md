# Utilisation pratique de Vault avec Datligent

## 🚀 Démarrage rapide

```bash
# 1. Charger la configuration Vault
source .env.vault

# 2. Vérifier la connexion
vault status
```

## 📊 Commandes essentielles pour Datligent

### Secrets Backstage

```bash
# Consulter tous les secrets Backstage
vault kv list datligent/backstage/

# Récupérer le secret d'authentification backend
vault kv get -field=backend_secret datligent/backstage/auth

# Mettre à jour le token GitHub
vault kv patch datligent/backstage/github token="ghp_nouveau_token_github"
```

### Secrets Gitea

```bash
# Récupérer les credentials admin
vault kv get datligent/gitea/admin

# Obtenir uniquement le mot de passe admin
vault kv get -field=password datligent/gitea/admin

# Mettre à jour le mot de passe de la base de données
vault kv patch datligent/gitea/database password="nouveau_mdp_securise"
```

### Secrets LDAP

```bash
# Consulter les credentials LDAP admin
vault kv get datligent/ldap/admin

# Récupérer uniquement le bind DN
vault kv get -field=bind_dn datligent/ldap/admin
```

## 🔧 Intégration dans les applications

### Script d'exemple pour récupérer des secrets

```bash
#!/bin/bash
# Exemple: récupérer les secrets Backstage pour configuration

# Charger les variables Vault
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="datligent-root-token"

# Récupérer les secrets
BACKEND_SECRET=$(vault kv get -field=backend_secret datligent/backstage/auth)
DB_PASSWORD=$(vault kv get -field=password datligent/backstage/database)
GITHUB_TOKEN=$(vault kv get -field=token datligent/backstage/github)

# Utiliser dans votre application
echo "BACKEND_SECRET=$BACKEND_SECRET" > .env
echo "DB_PASSWORD=$DB_PASSWORD" >> .env
echo "GITHUB_TOKEN=$GITHUB_TOKEN" >> .env
```

### Intégration avec Docker Compose

```yaml
# Exemple d'utilisation des secrets dans docker-compose
services:
  backstage:
    image: backstage:latest
    environment:
      - BACKEND_SECRET_FROM_VAULT=${BACKEND_SECRET}
    env_file:
      - vault-secrets.env
```

## 🛡️ Bonnes pratiques de sécurité

1. **Tokens d'application** : Utilisez des tokens avec permissions limitées
2. **Rotation des secrets** : Changez régulièrement les mots de passe
3. **Audit** : Surveillez les accès aux secrets
4. **Backup** : Sauvegardez vos données Vault

### Créer un token pour Backstage

```bash
# Créer un token avec permissions limitées
vault token create -policy=backstage-policy -ttl=720h
```

### Changer un secret de manière sécurisée

```bash
# Générer un nouveau mot de passe fort
NEW_PASSWORD=$(openssl rand -base64 32)

# Mettre à jour le secret
vault kv patch datligent/gitea/admin password="$NEW_PASSWORD"
```

## 📈 Monitoring et maintenance

```bash
# Vérifier la santé de Vault
vault status

# Lister tous les secrets
vault kv list -format=json datligent/

# Consulter les métadonnées d'un secret
vault kv metadata get datligent/backstage/auth

# Voir l'historique des versions
vault kv get -version=1 datligent/gitea/admin
```

## 🔐 Interface Web

Accès à l'interface Vault UI : http://localhost:8080/ui/

- **Token** : `datligent-root-token`
- **Moteurs** : `datligent/` et `infrastructure/`
- **Navigation** : Secrets Engine → datligent → backstage/gitea/ldap