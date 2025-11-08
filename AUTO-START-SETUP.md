# Configuration du Démarrage Automatique de Vault

## 🎯 Objectif

Assurer que Vault démarre automatiquement et soit **déscellé** après chaque redémarrage du Mac.

## ✅ Configuration Complétée

### 1. Docker Auto-Restart

Les conteneurs Docker sont configurés avec `restart: unless-stopped` dans `docker-compose-persistent.yml` :
- ✅ `vault-datligent` - Serveur Vault principal
- ✅ `vault-ui-datligent` - Interface web Nginx
- ✅ `vault-mcp-datligent` - Serveur MCP

**Résultat** : Les conteneurs redémarrent automatiquement après un reboot du Mac (si Docker Desktop est lancé).

### 2. Auto-Unseal au Démarrage

#### Script d'auto-unseal

**Emplacement** : `scripts/vault-auto-unseal.sh`

**Fonctionnalités** :
- Attend que Docker soit prêt
- Attend que le conteneur Vault soit démarré
- Attend que l'API Vault soit accessible
- Vérifie si Vault est scellé
- Déscelle automatiquement Vault si nécessaire
- Logs détaillés dans `vault-logs/auto-unseal.log`

#### LaunchAgent macOS

**Emplacement** : `~/Library/LaunchAgents/com.datligent.vault-autounseal.plist`

**Configuration** :
- ✅ S'exécute au démarrage (`RunAtLoad`)
- ✅ Se relance toutes les 5 minutes (`StartInterval: 300`)
- ✅ Throttle de 60s entre tentatives
- ✅ Logs dans `vault-logs/launchagent-*.log`

**Chargement** :
```bash
launchctl load ~/Library/LaunchAgents/com.datligent.vault-autounseal.plist
```

**Vérification** :
```bash
launchctl list | grep vault-autounseal
```

## 🔄 Workflow au Redémarrage

```
┌─────────────────────────────────────┐
│  1. Mac redémarre                   │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│  2. Docker Desktop démarre          │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│  3. Conteneurs Vault démarrent      │
│     (restart: unless-stopped)       │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│  4. LaunchAgent s'exécute           │
│     (RunAtLoad: true)               │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│  5. Script attend Docker + Vault    │
│     (max 30 retries × 5s)           │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│  6. Vault est déscellé              │
│     automatiquement                 │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│  ✅ Vault prêt et accessible        │
└─────────────────────────────────────┘
```

## 🧪 Test du Redémarrage Automatique

### Test 1 : Redémarrage des conteneurs

```bash
# Arrêter tous les conteneurs
docker-compose -f docker-compose-persistent.yml down

# Redémarrer
docker-compose -f docker-compose-persistent.yml up -d

# Vérifier
docker ps --filter "name=vault"
```

### Test 2 : Auto-unseal manuel

```bash
# Sceller Vault manuellement
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="<VAULT_ROOT_TOKEN>"
vault operator seal

# Déclencher l'auto-unseal
./scripts/vault-auto-unseal.sh

# Vérifier les logs
tail -f vault-logs/auto-unseal.log
```

### Test 3 : LaunchAgent

```bash
# Déclencher manuellement le LaunchAgent
launchctl start com.datligent.vault-autounseal

# Vérifier les logs
tail -f vault-logs/launchagent-stdout.log
tail -f vault-logs/launchagent-stderr.log
```

### Test 4 : Redémarrage complet du Mac

```bash
# Avant le reboot, vérifier la config
launchctl list | grep vault-autounseal

# Reboot
sudo reboot

# Après le reboot (attendre ~2 minutes)
export VAULT_ADDR="http://localhost:8200"
vault status  # Devrait montrer "Sealed: false"
```

## 📊 Monitoring et Maintenance

### Vérifier le statut

```bash
# Statut des conteneurs
docker ps --filter "name=vault" --format "table {{.Names}}\t{{.Status}}"

# Statut Vault
export VAULT_ADDR="http://localhost:8200"
vault status

# Statut LaunchAgent
launchctl list | grep vault-autounseal
```

### Consulter les logs

```bash
# Logs auto-unseal
tail -f vault-logs/auto-unseal.log

# Logs LaunchAgent
tail -f vault-logs/launchagent-stdout.log
tail -f vault-logs/launchagent-stderr.log

# Logs conteneur Vault
docker logs vault-datligent --tail 50
```

### Health Check complet

```bash
./scripts/vault-health-check.sh
```

## 🔧 Dépannage

### Problème : Vault reste scellé après reboot

**Diagnostic** :
```bash
# Vérifier les logs d'auto-unseal
cat vault-logs/auto-unseal.log

# Vérifier le LaunchAgent
launchctl list | grep vault-autounseal
```

**Solutions** :
1. Relancer manuellement l'auto-unseal :
   ```bash
   ./scripts/vault-auto-unseal.sh
   ```

2. Recharger le LaunchAgent :
   ```bash
   launchctl unload ~/Library/LaunchAgents/com.datligent.vault-autounseal.plist
   launchctl load ~/Library/LaunchAgents/com.datligent.vault-autounseal.plist
   ```

### Problème : Conteneurs ne démarrent pas

**Diagnostic** :
```bash
docker ps -a --filter "name=vault"
docker logs vault-datligent
```

**Solutions** :
1. Vérifier Docker Desktop est lancé
2. Redémarrer les conteneurs :
   ```bash
   docker-compose -f docker-compose-persistent.yml restart
   ```

### Problème : LaunchAgent ne se lance pas

**Diagnostic** :
```bash
launchctl list | grep vault-autounseal
cat vault-logs/launchagent-stderr.log
```

**Solutions** :
1. Vérifier les permissions :
   ```bash
   chmod +x scripts/vault-auto-unseal.sh
   ```

2. Vérifier le plist :
   ```bash
   plutil -lint ~/Library/LaunchAgents/com.datligent.vault-autounseal.plist
   ```

## 🎯 Avantages de cette Configuration

### ✅ Résilience
- Vault redémarre automatiquement après crash ou reboot
- Auto-unseal garantit que Vault est toujours accessible
- Retry logic robuste (30 tentatives × 5s)

### ✅ Maintenance Zéro
- Pas d'intervention manuelle nécessaire après reboot
- Surveillance automatique toutes les 5 minutes
- Logs détaillés pour debugging

### ✅ Sécurité
- Clés de déscellement stockées localement dans `init-data/`
- Pas de clés hardcodées dans le code
- Throttling pour éviter les boucles infinies

### ✅ Compatibilité
- Fonctionne avec docker-compose-persistent.yml
- Compatible avec tous les outils IA (Claude Code, etc.)
- Pas d'impact sur les performances

## 📝 Fichiers Créés

```
vault-datligent/
├── scripts/
│   └── vault-auto-unseal.sh           # Script d'auto-unseal
├── vault-logs/
│   ├── auto-unseal.log                # Logs du script
│   ├── launchagent-stdout.log         # Logs LaunchAgent stdout
│   └── launchagent-stderr.log         # Logs LaunchAgent stderr
└── ~/Library/LaunchAgents/
    └── com.datligent.vault-autounseal.plist  # Service macOS
```

## 🚀 Commandes Utiles

```bash
# Démarrer Vault
docker-compose -f docker-compose-persistent.yml up -d

# Arrêter Vault
docker-compose -f docker-compose-persistent.yml down

# Sceller Vault (pour tests)
vault operator seal

# Désceller manuellement
vault operator unseal <UNSEAL_KEY>

# Auto-unseal manuel
./scripts/vault-auto-unseal.sh

# Recharger LaunchAgent
launchctl unload ~/Library/LaunchAgents/com.datligent.vault-autounseal.plist
launchctl load ~/Library/LaunchAgents/com.datligent.vault-autounseal.plist

# Health check complet
./scripts/vault-health-check.sh

# Test Gmail OAuth
./scripts/test-gmail-vault.sh
```

---

**Configuration réalisée le** : 2025-10-10
**Testée et validée** : ✅
**Prêt pour production** : ✅
