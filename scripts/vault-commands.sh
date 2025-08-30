#!/bin/bash
# Script d'exemples de commandes Vault pour l'infrastructure Datligent

# Charger la configuration
source ../env.vault

echo "🔐 Exemples de commandes Vault pour Datligent"
echo "=============================================="

echo ""
echo "📊 1. Lister tous les secrets:"
echo "   vault kv list datligent/"
echo "   vault kv list infrastructure/"

echo ""
echo "🔍 2. Consulter des secrets spécifiques:"
echo "   vault kv get datligent/backstage/auth"
echo "   vault kv get datligent/gitea/admin"
echo "   vault kv get datligent/ldap/admin"

echo ""
echo "✏️  3. Modifier un secret:"
echo "   vault kv put datligent/backstage/auth backend_secret=\"nouvelle-clé\""
echo "   vault kv patch datligent/gitea/admin password=\"nouveau-mot-de-passe\""

echo ""
echo "🗑️  4. Supprimer un secret:"
echo "   vault kv delete datligent/backstage/temp"

echo ""
echo "📝 5. Consulter l'historique des versions:"
echo "   vault kv metadata get datligent/backstage/auth"

echo ""
echo "🎫 6. Gérer les tokens:"
echo "   vault token lookup"
echo "   vault token create -policy=backstage-policy"

echo ""
echo "📜 7. Consulter les politiques:"
echo "   vault policy list"
echo "   vault policy read backstage-policy"

echo ""
echo "🔧 8. Status et santé:"
echo "   vault status"
echo "   vault operator raft list-peers"

echo ""
echo "💡 Pour exécuter ces commandes, assurez-vous d'avoir:"
echo "   - Vault installé: brew install hashicorp/tap/vault"
echo "   - Configuration chargée: source .env.vault"
echo "   - Services Vault démarrés: docker-compose -f docker-compose-simple.yml up -d"