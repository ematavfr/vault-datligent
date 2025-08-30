#!/bin/bash
set -e

# Script de configuration des secrets Datligent via API REST
echo "🔐 Configuration des secrets Datligent dans Vault (via API)..."

# Variables
VAULT_ADDR="http://localhost:8200"
VAULT_TOKEN="datligent-root-token"

# Headers pour les requêtes
HEADERS="Content-Type: application/json"
AUTH_HEADER="X-Vault-Token: ${VAULT_TOKEN}"

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

# Moteur pour les secrets Datligent
curl -s -X POST \
    -H "${HEADERS}" \
    -H "${AUTH_HEADER}" \
    -d '{"type":"kv-v2"}' \
    ${VAULT_ADDR}/v1/sys/mounts/datligent 2>/dev/null || echo "Moteur datligent existe déjà"

# Moteur pour l'infrastructure
curl -s -X POST \
    -H "${HEADERS}" \
    -H "${AUTH_HEADER}" \
    -d '{"type":"kv-v2"}' \
    ${VAULT_ADDR}/v1/sys/mounts/infrastructure 2>/dev/null || echo "Moteur infrastructure existe déjà"

# Secrets Backstage
echo "📊 Configuration des secrets Backstage..."

curl -s -X POST \
    -H "${HEADERS}" \
    -H "${AUTH_HEADER}" \
    -d '{"data":{"backend_secret":"backstage-datligent-secret-key-2025","session_secret":"backstage-session-secret-datligent"}}' \
    ${VAULT_ADDR}/v1/datligent/data/backstage/auth

curl -s -X POST \
    -H "${HEADERS}" \
    -H "${AUTH_HEADER}" \
    -d '{"data":{"username":"backstage","password":"backstage_secure_pass_datligent_2025","host":"localhost","port":"5432","database":"backstage_plugin_catalog"}}' \
    ${VAULT_ADDR}/v1/datligent/data/backstage/database

curl -s -X POST \
    -H "${HEADERS}" \
    -H "${AUTH_HEADER}" \
    -d '{"data":{"token":"ghp_replace_with_real_github_token","app_id":"replace_with_github_app_id"}}' \
    ${VAULT_ADDR}/v1/datligent/data/backstage/github

# Secrets Gitea
echo "🦎 Configuration des secrets Gitea..."

curl -s -X POST \
    -H "${HEADERS}" \
    -H "${AUTH_HEADER}" \
    -d '{"data":{"username":"datligentadmin","password":"DataligentGitea2025!","email":"admin@datligent.local"}}' \
    ${VAULT_ADDR}/v1/datligent/data/gitea/admin

curl -s -X POST \
    -H "${HEADERS}" \
    -H "${AUTH_HEADER}" \
    -d '{"data":{"username":"gitea","password":"gitea_datligent_secure_2025","host":"db","port":"5432","database":"gitea"}}' \
    ${VAULT_ADDR}/v1/datligent/data/gitea/database

curl -s -X POST \
    -H "${HEADERS}" \
    -H "${AUTH_HEADER}" \
    -d '{"data":{"secret":"gitea-jwt-secret-datligent-2025-secure"}}' \
    ${VAULT_ADDR}/v1/datligent/data/gitea/jwt

# Secrets LDAP
echo "🔒 Configuration des secrets LDAP..."

curl -s -X POST \
    -H "${HEADERS}" \
    -H "${AUTH_HEADER}" \
    -d '{"data":{"bind_dn":"cn=admin,dc=datligent,dc=local","bind_password":"DataligentLDAP2025!","base_dn":"dc=datligent,dc=local"}}' \
    ${VAULT_ADDR}/v1/datligent/data/ldap/admin

curl -s -X POST \
    -H "${HEADERS}" \
    -H "${AUTH_HEADER}" \
    -d '{"data":{"bind_dn":"cn=readonly,dc=datligent,dc=local","bind_password":"ReadOnlyLDAP2025!","base_dn":"dc=datligent,dc=local"}}' \
    ${VAULT_ADDR}/v1/datligent/data/ldap/readonly

# Secrets d'infrastructure
echo "🏗️ Configuration des secrets d'infrastructure..."

curl -s -X POST \
    -H "${HEADERS}" \
    -H "${AUTH_HEADER}" \
    -d '{"data":{"ca_cert":"-----BEGIN CERTIFICATE----- ... -----END CERTIFICATE-----","ca_key":"-----BEGIN PRIVATE KEY----- ... -----END PRIVATE KEY-----"}}' \
    ${VAULT_ADDR}/v1/infrastructure/data/ssl/certificates

curl -s -X POST \
    -H "${HEADERS}" \
    -H "${AUTH_HEADER}" \
    -d '{"data":{"grafana_admin_password":"GrafanaDataligent2025!","prometheus_basic_auth":"prometheusDataligent2025!"}}' \
    ${VAULT_ADDR}/v1/infrastructure/data/monitoring

# Créer les politiques d'accès
echo "📜 Création des politiques de sécurité..."

# Politique pour Backstage
BACKSTAGE_POLICY='path "datligent/data/backstage/*" {\n  capabilities = ["create", "read", "update", "delete", "list"]\n}\npath "infrastructure/data/ssl/*" {\n  capabilities = ["read"]\n}\npath "datligent/data/*/database" {\n  capabilities = ["read"]\n}'

curl -s -X PUT \
    -H "${HEADERS}" \
    -H "${AUTH_HEADER}" \
    -d "{\"policy\":\"${BACKSTAGE_POLICY}\"}" \
    ${VAULT_ADDR}/v1/sys/policies/acl/backstage-policy

# Politique pour Gitea
GITEA_POLICY='path "datligent/data/gitea/*" {\n  capabilities = ["create", "read", "update", "delete", "list"]\n}\npath "infrastructure/data/ssl/*" {\n  capabilities = ["read"]\n}'

curl -s -X PUT \
    -H "${HEADERS}" \
    -H "${AUTH_HEADER}" \
    -d "{\"policy\":\"${GITEA_POLICY}\"}" \
    ${VAULT_ADDR}/v1/sys/policies/acl/gitea-policy

# Créer des tokens d'application avec politiques limitées
echo "🎫 Création des tokens d'application..."

# Token pour Backstage
BACKSTAGE_TOKEN=$(curl -s -X POST \
    -H "${HEADERS}" \
    -H "${AUTH_HEADER}" \
    -d '{"policies":["backstage-policy"],"ttl":"8760h"}' \
    ${VAULT_ADDR}/v1/auth/token/create | jq -r .auth.client_token)

# Token pour Gitea
GITEA_TOKEN=$(curl -s -X POST \
    -H "${HEADERS}" \
    -H "${AUTH_HEADER}" \
    -d '{"policies":["gitea-policy"],"ttl":"8760h"}' \
    ${VAULT_ADDR}/v1/auth/token/create | jq -r .auth.client_token)

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