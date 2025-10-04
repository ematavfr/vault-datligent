ui = true

# Stockage persistant sur disque
storage "file" {
  path = "/vault/data"
}

# Listener HTTP (pour dev/test)
listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}

# API et Cluster addresses
api_addr = "http://0.0.0.0:8200"
cluster_addr = "http://0.0.0.0:8201"

# Désactiver mlock pour Docker (dev uniquement)
disable_mlock = true

# Log level
log_level = "info"
