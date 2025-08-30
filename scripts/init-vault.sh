#!/bin/bash
set -e

# Script d'initialisation du cluster Vault Datligent
echo "🔐 Initialisation du cluster Vault Datligent..."

# Variables
VAULT_ADDR="http://vault-lb"
INIT_FILE="/init-data/vault-init.json"
ROOT_TOKEN_FILE="/init-data/root-token"
UNSEAL_KEYS_FILE="/init-data/unseal-keys"

# Attendre que Vault soit disponible
echo "⏳ Attente de la disponibilité de Vault..."
until curl -sf ${VAULT_ADDR}/v1/sys/health >/dev/null 2>&1; do
    echo "En attente de Vault..."
    sleep 5
done

echo "✅ Vault est disponible!"

# Vérifier si Vault est déjà initialisé
if curl -sf ${VAULT_ADDR}/v1/sys/init | jq -r .initialized | grep -q true; then
    echo "ℹ️  Vault est déjà initialisé"
    exit 0
fi

# Initialiser Vault avec 5 clés de déchiffrement, seuil de 3
echo "🚀 Initialisation de Vault..."
curl -s -X POST \
    -d '{"secret_shares": 5, "secret_threshold": 3}' \
    ${VAULT_ADDR}/v1/sys/init > ${INIT_FILE}

if [ $? -eq 0 ]; then
    echo "✅ Vault initialisé avec succès!"
    
    # Extraire le token root et les clés de déchiffrement
    jq -r .root_token ${INIT_FILE} > ${ROOT_TOKEN_FILE}
    jq -r .keys[] ${INIT_FILE} > ${UNSEAL_KEYS_FILE}
    
    echo "🔑 Token root sauvegardé dans: ${ROOT_TOKEN_FILE}"
    echo "🗝️  Clés de déchiffrement sauvegardées dans: ${UNSEAL_KEYS_FILE}"
    
    # Déchiffrer Vault avec les 3 premières clés
    echo "🔓 Déchiffrement de Vault..."
    head -3 ${UNSEAL_KEYS_FILE} | while read key; do
        curl -s -X POST -d "{\"key\":\"$key\"}" ${VAULT_ADDR}/v1/sys/unseal
    done
    
    # Vérifier le statut
    if curl -sf ${VAULT_ADDR}/v1/sys/health | jq -r .sealed | grep -q false; then
        echo "✅ Vault déchiffré avec succès!"
        
        # Configuration initiale
        export VAULT_TOKEN=$(cat ${ROOT_TOKEN_FILE})
        
        # Activer les moteurs de secrets KV
        echo "🔧 Configuration des moteurs de secrets..."
        curl -s -X POST \
            -H "X-Vault-Token: ${VAULT_TOKEN}" \
            -d '{"type":"kv-v2"}' \
            ${VAULT_ADDR}/v1/sys/mounts/datligent
            
        curl -s -X POST \
            -H "X-Vault-Token: ${VAULT_TOKEN}" \
            -d '{"type":"kv-v2"}' \
            ${VAULT_ADDR}/v1/sys/mounts/infrastructure
            
        # Créer les politiques de base
        echo "📜 Création des politiques de sécurité..."
        
        # Politique pour Backstage
        cat > /tmp/backstage-policy.hcl << EOF
path "datligent/data/backstage/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "infrastructure/data/database/*" {
  capabilities = ["read"]
}
EOF
        
        curl -s -X PUT \
            -H "X-Vault-Token: ${VAULT_TOKEN}" \
            -d "{\"policy\":\"$(cat /tmp/backstage-policy.hcl)\"}" \
            ${VAULT_ADDR}/v1/sys/policies/acl/backstage-policy
            
        # Politique pour Gitea
        cat > /tmp/gitea-policy.hcl << EOF
path "datligent/data/gitea/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "infrastructure/data/database/*" {
  capabilities = ["read"]
}
EOF
        
        curl -s -X PUT \
            -H "X-Vault-Token: ${VAULT_TOKEN}" \
            -d "{\"policy\":\"$(cat /tmp/gitea-policy.hcl)\"}" \
            ${VAULT_ADDR}/v1/sys/policies/acl/gitea-policy
            
        echo "✅ Configuration initiale terminée!"
        echo ""
        echo "🎉 Cluster Vault Datligent prêt!"
        echo "📍 Interface Web: http://localhost:8080/ui/"
        echo "🔑 Token root: $(cat ${ROOT_TOKEN_FILE})"
        echo ""
        echo "⚠️  IMPORTANT: Sauvegardez les clés de déchiffrement dans un endroit sûr!"
        
    else
        echo "❌ Erreur lors du déchiffrement de Vault"
        exit 1
    fi
else
    echo "❌ Erreur lors de l'initialisation de Vault"
    exit 1
fi