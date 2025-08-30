# Vault Cluster Datligent

Infrastructure de gestion de secrets centralisée pour l'écosystème Datligent.

## 🏗️ Architecture

- **3 nœuds Vault** en cluster avec Raft storage
- **Load Balancer Nginx** pour la haute disponibilité
- **Interface Web** accessible via http://localhost:8080
- **API REST** pour l'intégration avec les services

## 🚀 Déploiement

```bash
# Démarrer le cluster
docker-compose up -d

# Vérifier le statut
docker-compose ps

# Voir les logs
docker-compose logs -f vault-1
```

## 🔐 Initialisation

Le script `init-vault.sh` s'exécute automatiquement et :
1. Initialise le cluster Vault
2. Génère 5 clés de déchiffrement (seuil: 3)
3. Déchiffre automatiquement Vault
4. Configure les moteurs de secrets
5. Crée les politiques de base

## 📍 Accès

- **Interface Web**: http://localhost:8080/ui/
- **API Vault**: http://localhost:8080/v1/
- **Health Check**: http://localhost:8080/v1/sys/health

### Nœuds individuels

- **Vault-1**: http://localhost:8200
- **Vault-2**: http://localhost:8201  
- **Vault-3**: http://localhost:8202

## 🔑 Secrets organisés

### Moteurs de secrets

- **datligent/**: Secrets spécifiques aux applications
  - `datligent/backstage/*`: Secrets Backstage
  - `datligent/gitea/*`: Secrets Gitea
  - `datligent/ldap/*`: Secrets LDAP

- **infrastructure/**: Secrets d'infrastructure
  - `infrastructure/database/*`: Credentials BDD
  - `infrastructure/ssl/*`: Certificats TLS

## 🛡️ Politiques de sécurité

- **backstage-policy**: Accès aux secrets Backstage + lecture BDD
- **gitea-policy**: Accès aux secrets Gitea + lecture BDD
- **ldap-policy**: Accès aux secrets LDAP

## 📊 Intégration avec l'écosystème Datligent

### Gitea (localhost:3005)
```bash
# Stocker le mot de passe admin Gitea
vault kv put datligent/gitea/admin password="admin_secure_password"
```

### Backstage (localhost:3025)
```bash
# Stocker les tokens Backstage
vault kv put datligent/backstage/github token="ghp_your_token"
vault kv put datligent/backstage/backend secret="backend_secret_key"
```

### LDAP (localhost:3389)
```bash
# Stocker le mot de passe bind LDAP
vault kv put datligent/ldap/admin password="AdminPass123!"
```

## 🔧 Commandes utiles

```bash
# Status du cluster
curl http://localhost:8080/v1/sys/health

# Liste des nœuds
vault operator raft list-peers

# Rotation des clés de chiffrement
vault operator rotate

# Sauvegarde
vault operator raft snapshot save backup.snap
```

## ⚠️ Sécurité

1. **Sauvegardez** les clés de déchiffrement dans un endroit sûr
2. **Changez** le token root après configuration initiale
3. **Utilisez** des tokens avec permissions limitées pour les applications
4. **Activez** l'audit logging en production
5. **Configurez** TLS pour les communications

## 📁 Structure des fichiers

```
vault-datligent/
├── docker-compose.yml          # Configuration Docker Compose
├── config/
│   ├── vault-1.hcl            # Config nœud 1
│   ├── vault-2.hcl            # Config nœud 2
│   ├── vault-3.hcl            # Config nœud 3
│   └── nginx.conf             # Config load balancer
├── scripts/
│   └── init-vault.sh          # Script d'initialisation
├── init-data/                 # Données d'initialisation (tokens, clés)
└── README.md
```