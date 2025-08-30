#!/bin/bash
set -e

# Script de configuration des secrets Datligent dans Vault
echo "🔐 Configuration des secrets Datligent dans Vault..."

# Variables
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="datligent-root-token"

# Fonction pour attendre que Vault soit disponible
wait_for_vault() {
    echo "⏳ Attente de la disponibilité de Vault..."
    until curl -sf ${VAULT_ADDR}/v1/sys/health >/dev/null 2>&1; do
        echo "En attente de Vault..."
        sleep 2
    done
    echo "✅ Vault est disponible!"
}

# Attendre Vault
wait_for_vault

# Activer les moteurs de secrets KV v2
echo "🔧 Configuration des moteurs de secrets..."

# Moteur pour les secrets spécifiques aux applications Datligent
vault secrets enable -path=datligent kv-v2 2>/dev/null || echo "Moteur datligent déjà activé"

# Moteur pour les secrets d'infrastructure
vault secrets enable -path=infrastructure kv-v2 2>/dev/null || echo "Moteur infrastructure déjà activé"

# Secrets Backstage
echo "📊 Configuration des secrets Backstage..."
vault kv put datligent/backstage/auth \
    backend_secret="backstage-datligent-secret-key-2025" \
    session_secret="backstage-session-secret-datligent"

vault kv put datligent/backstage/database \
    username="backstage" \
    password="backstage_secure_pass_datligent_2025" \
    host="localhost" \
    port="5432" \
    database="backstage_plugin_catalog"

vault kv put datligent/backstage/github \
    token="ghp_replace_with_real_github_token" \
    app_id="replace_with_github_app_id"

# Secrets Gitea
echo "🦎 Configuration des secrets Gitea..."
vault kv put datligent/gitea/admin \
    username="datligentadmin" \
    password="DataligentGitea2025!" \
    email="admin@datligent.local"

vault kv put datligent/gitea/database \
    username="gitea" \
    password="gitea_datligent_secure_2025" \
    host="db" \
    port="5432" \
    database="gitea"

vault kv put datligent/gitea/jwt \
    secret="gitea-jwt-secret-datligent-2025-secure"

# Secrets LDAP
echo "🔒 Configuration des secrets LDAP..."
vault kv put datligent/ldap/admin \
    bind_dn="cn=admin,dc=datligent,dc=local" \
    bind_password="DataligentLDAP2025!" \
    base_dn="dc=datligent,dc=local"

vault kv put datligent/ldap/readonly \
    bind_dn="cn=readonly,dc=datligent,dc=local" \
    bind_password="ReadOnlyLDAP2025!" \
    base_dn="dc=datligent,dc=local"

# Secrets d'infrastructure
echo "🏗️ Configuration des secrets d'infrastructure..."
vault kv put infrastructure/ssl/certificates \
    ca_cert="-----BEGIN CERTIFICATE----- ... -----END CERTIFICATE-----" \
    ca_key="-----BEGIN PRIVATE KEY----- ... -----END PRIVATE KEY-----"

vault kv put infrastructure/monitoring \
    grafana_admin_password="GrafanaDataligent2025!" \
    prometheus_basic_auth="prometheusDataligent2025!"

# Créer les politiques d'accès
echo "📜 Création des politiques de sécurité..."

# Politique pour Backstage
cat > /tmp/backstage-policy.hcl << 'EOF'
# Accès aux secrets Backstage
path "datligent/data/backstage/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Accès en lecture aux secrets d'infrastructure
path "infrastructure/data/ssl/*" {
  capabilities = ["read"]
}

# Accès en lecture aux secrets de base de données
path "datligent/data/*/database" {
  capabilities = ["read"]
}
EOF

vault policy write backstage-policy /tmp/backstage-policy.hcl

# Politique pour Gitea
cat > /tmp/gitea-policy.hcl << 'EOF'
# Accès aux secrets Gitea
path "datligent/data/gitea/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Accès en lecture aux secrets SSL
path "infrastructure/data/ssl/*" {
  capabilities = ["read"]
}
EOF

vault policy write gitea-policy /tmp/gitea-policy.hcl

# Politique pour LDAP
cat > /tmp/ldap-policy.hcl << 'EOF'
# Accès aux secrets LDAP
path "datligent/data/ldap/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
EOF

vault policy write ldap-policy /tmp/ldap-policy.hcl

# Créer des tokens d'application avec politiques limitées
echo "🎫 Création des tokens d'application..."

# Token pour Backstage
BACKSTAGE_TOKEN=$(vault token create -policy=backstage-policy -ttl=8760h -format=json | jq -r .auth.client_token)
echo "Token Backstage: ${BACKSTAGE_TOKEN}"

# Token pour Gitea  
GITEA_TOKEN=$(vault token create -policy=gitea-policy -ttl=8760h -format=json | jq -r .auth.client_token)
echo "Token Gitea: ${GITEA_TOKEN}"

# Sauvegarder les tokens
mkdir -p ../tokens
echo "${BACKSTAGE_TOKEN}" > ../tokens/backstage-token
echo "${GITEA_TOKEN}" > ../tokens/gitea-token

echo ""
echo "✅ Configuration des secrets Datligent terminée!"
echo ""
echo "📍 Accès Vault:"
echo "   - Interface Web: http://localhost:8080/ui/"
echo "   - API: http://localhost:8080/v1/"
echo "   - Token root: datligent-root-token"
echo ""
echo "🎫 Tokens d'application:"
echo "   - Backstage: ${BACKSTAGE_TOKEN}"
echo "   - Gitea: ${GITEA_TOKEN}"
echo ""
echo "🔐 Secrets configurés:"
echo "   - datligent/backstage/* (auth, database, github)"
echo "   - datligent/gitea/* (admin, database, jwt)" 
echo "   - datligent/ldap/* (admin, readonly)"
echo "   - infrastructure/* (ssl, monitoring)"
echo ""
echo "📊 Interface Web accessible sur: http://localhost:8080"