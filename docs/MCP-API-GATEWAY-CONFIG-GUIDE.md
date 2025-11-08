# Guide de Configuration : mcp-api-gateway sur Docker Desktop

## 🎯 Objectif

Configurer le serveur MCP **mcp-api-gateway** dans Docker Desktop pour exposer vos APIs REST comme des outils MCP, avec authentification gérée par Vault.

## 📋 Formulaire Docker Desktop

Le formulaire demande 3 informations pour configurer votre API :

### 1. **api_1_name** - Nom de votre API
**Description** : Un nom descriptif pour identifier votre API

**Exemples** :
```
my-service
weather-api
internal-crm
```

**Source** : Vous choisissez librement

### 2. **api_1_swagger_url** - URL de la spécification OpenAPI
**Description** : URL vers le fichier OpenAPI/Swagger de votre API

**Exemples** :
```
https://petstore3.swagger.io/api/v3/openapi.json
https://api.example.com/swagger.json
http://localhost:3000/api-docs
```

**Source** : Documentation de votre API

### 3. **api_1_header_authorization** - Header d'authentification
**Description** : Le header Authorization pour authentifier les requêtes

**⚠️ C'EST ICI QU'ON UTILISE VAULT !**

## 🔐 Utiliser Vault pour les Secrets

### Étape 1 : Stocker le token dans Vault

```bash
# Pour une API avec Bearer Token
vault kv put datligent/mcp/shared/my-api \
  authorization="Bearer sk-1234567890abcdef" \
  swagger_url="https://api.example.com/swagger.json" \
  description="Mon API personnalisée"

# Pour une API avec API Key
vault kv put datligent/mcp/shared/weather-api \
  authorization="ApiKey xyz123abc456" \
  swagger_url="https://weatherapi.com/openapi.json" \
  description="Weather API"
```

### Étape 2 : Récupérer le secret depuis Vault

```bash
# Lire le secret
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="<VAULT_ROOT_TOKEN>"

vault kv get -format=json datligent/mcp/shared/my-api | jq -r '.data.data.authorization'
```

**Résultat** : `Bearer sk-1234567890abcdef`

### Étape 3 : Copier dans Docker Desktop

1. Exécuter la commande ci-dessus
2. Copier le résultat (avec `Bearer` ou `ApiKey` inclus)
3. Coller dans le champ `api_1_header_authorization`

## 📝 Exemples Complets

### Exemple 1 : API Petstore (publique, pas d'auth)

**Formulaire Docker Desktop** :
```
api_1_name: petstore
api_1_swagger_url: https://petstore3.swagger.io/api/v3/openapi.json
api_1_header_authorization: (vide ou "none")
```

**Pas besoin de Vault** car pas d'authentification.

### Exemple 2 : API Interne avec Bearer Token

**1. Stocker dans Vault** :
```bash
vault kv put datligent/mcp/shared/internal-api \
  authorization="Bearer eyJhbGciOiJIUzI1NiIs..." \
  swagger_url="https://internal.example.com/api/swagger.json" \
  description="API interne de l'entreprise"
```

**2. Récupérer pour Docker Desktop** :
```bash
vault kv get -format=json datligent/mcp/shared/internal-api | \
  jq -r '.data.data.authorization'
```

**3. Remplir le formulaire** :
```
api_1_name: internal-api
api_1_swagger_url: https://internal.example.com/api/swagger.json
api_1_header_authorization: Bearer eyJhbGciOiJIUzI1NiIs...
```

### Exemple 3 : API avec API Key

**1. Stocker dans Vault** :
```bash
vault kv put datligent/mcp/shared/weatherapi \
  api_key="abc123def456" \
  authorization="X-API-Key abc123def456" \
  swagger_url="https://api.weatherapi.com/openapi.json" \
  description="Weather API"
```

**2. Récupérer pour Docker Desktop** :
```bash
vault kv get -format=json datligent/mcp/shared/weatherapi | \
  jq -r '.data.data.authorization'
```

**3. Remplir le formulaire** :
```
api_1_name: weatherapi
api_1_swagger_url: https://api.weatherapi.com/openapi.json
api_1_header_authorization: X-API-Key abc123def456
```

## 🔄 Workflow Recommandé

```
┌─────────────────────────────────────────┐
│ 1. Identifier votre API                 │
│    - Nom                                 │
│    - URL Swagger                         │
│    - Type d'auth (Bearer/ApiKey/Basic)  │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│ 2. Stocker dans Vault                   │
│    vault kv put datligent/mcp/shared/   │
│      <api-name> authorization="..."     │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│ 3. Récupérer depuis Vault               │
│    vault kv get -format=json ... | jq   │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│ 4. Configurer dans Docker Desktop       │
│    - Ouvrir Docker Desktop               │
│    - MCP Servers → mcp-api-gateway       │
│    - Remplir le formulaire               │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│ 5. Tester dans Claude Desktop           │
│    - Redémarrer Claude Desktop           │
│    - Vérifier que l'API est accessible   │
└─────────────────────────────────────────┘
```

## 🛠️ Script Helper pour Vault

Créons un script pour faciliter la configuration :

```bash
#!/bin/bash
# scripts/get-mcp-api-auth.sh
# Récupère l'authorization header depuis Vault pour Docker Desktop

API_NAME=$1

if [ -z "$API_NAME" ]; then
  echo "Usage: $0 <api-name>"
  echo "Example: $0 weatherapi"
  exit 1
fi

export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="<VAULT_ROOT_TOKEN>"

AUTH=$(vault kv get -format=json "datligent/mcp/shared/$API_NAME" 2>/dev/null | \
  jq -r '.data.data.authorization // empty')

if [ -z "$AUTH" ]; then
  echo "❌ Secret not found: datligent/mcp/shared/$API_NAME"
  exit 1
fi

echo "✅ Authorization header for $API_NAME:"
echo ""
echo "$AUTH"
echo ""
echo "👉 Copy the value above and paste it into Docker Desktop"
```

**Usage** :
```bash
chmod +x scripts/get-mcp-api-auth.sh
./scripts/get-mcp-api-auth.sh weatherapi
```

## 📚 Formats d'Authorization selon le type d'API

### Bearer Token (OAuth, JWT)
```
Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### API Key dans le header
```
X-API-Key: abc123def456
ApiKey abc123def456
```

### Basic Authentication
```
Basic dXNlcm5hbWU6cGFzc3dvcmQ=
```
(Base64 de `username:password`)

### Custom Header
```
X-Custom-Auth: your-token-here
```

## ⚠️ Sécurité

### ✅ FAIRE
- Stocker TOUS les tokens dans Vault
- Utiliser des tokens avec TTL limité
- Rotation régulière des API keys
- Utiliser `vault kv get` pour récupérer les secrets

### ❌ NE PAS FAIRE
- Hardcoder les tokens dans les configs
- Partager les tokens par email/Slack
- Commiter les tokens dans Git
- Copier-coller les tokens sans passer par Vault

## 🎯 APIs Courantes à Configurer

### 1. OpenAI API
```bash
vault kv put datligent/mcp/shared/openai-api \
  authorization="Bearer sk-..." \
  swagger_url="https://api.openai.com/v1/openapi.json" \
  description="OpenAI API"
```

### 2. Anthropic API
```bash
vault kv put datligent/mcp/shared/anthropic-api \
  authorization="x-api-key sk-ant-..." \
  swagger_url="https://api.anthropic.com/openapi.json" \
  description="Anthropic Claude API"
```

### 3. GitHub API
```bash
vault kv put datligent/mcp/shared/github-api \
  authorization="Bearer ghp_..." \
  swagger_url="https://api.github.com/openapi.json" \
  description="GitHub REST API"
```

## 🔍 Troubleshooting

### Problème : "Authentication failed"

**Cause** : Token invalide ou expiré

**Solution** :
```bash
# Tester le token manuellement
TOKEN=$(vault kv get -format=json datligent/mcp/shared/my-api | \
  jq -r '.data.data.authorization')

curl -H "Authorization: $TOKEN" \
  https://api.example.com/v1/test
```

### Problème : "Swagger URL not accessible"

**Cause** : URL incorrecte ou API non publique

**Solution** :
```bash
# Tester l'URL Swagger
curl -I https://api.example.com/swagger.json
```

### Problème : "Secret not found in Vault"

**Cause** : Secret pas encore créé

**Solution** :
```bash
# Créer le secret
vault kv put datligent/mcp/shared/my-api \
  authorization="Bearer ..." \
  swagger_url="..."
```

## 📖 Documentation Supplémentaire

- **mcp-api-gateway GitHub** : https://github.com/michaelpoluektov/mcp-api-gateway
- **OpenAPI Specification** : https://swagger.io/specification/
- **Vault KV Secrets** : https://www.vaultproject.io/docs/secrets/kv

---

**Créé le** : 2025-10-10
**Dernière mise à jour** : 2025-10-10
