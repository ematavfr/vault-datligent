# Configuration Vault Node 3
ui = true
cluster_name = "datligent-vault-cluster"

# API Listener
listener "tcp" {
  address         = "0.0.0.0:8200"
  cluster_address = "0.0.0.0:8201"
  tls_disable     = 1
}

# Raft Storage Backend
storage "raft" {
  path = "/vault/data"
  node_id = "vault-3"
  
  retry_join {
    leader_api_addr = "http://vault-1:8200"
  }
  
  retry_join {
    leader_api_addr = "http://vault-2:8200"
  }
}

# API Address
api_addr = "http://vault-3:8200"
cluster_addr = "http://vault-3:8201"

# Logging
log_level = "info"
log_file = "/vault/logs/vault-3.log"

# Disable mlock (for containers)
disable_mlock = true

# Enable Prometheus metrics
telemetry {
  prometheus_retention_time = "30s"
  disable_hostname = true
}