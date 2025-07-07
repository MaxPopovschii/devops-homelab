#!/bin/bash

# Setup DevOps Homelab
# Questo script configura tutto l'ambiente

echo "🚀 Configurazione DevOps Homelab..."

# Crea struttura directory
mkdir -p homelab/{config,data,projects}
cd homelab

# Crea file di configurazione Traefik
cat > config/traefik.yml << 'EOF'
global:
  checkNewVersion: false
  sendAnonymousUsage: false

api:
  dashboard: true
  insecure: true

entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
    network: homelab

log:
  level: INFO

accessLog: {}
EOF

# Crea file acme.json per SSL
touch data/acme.json
chmod 600 data/acme.json

# Configurazione Prometheus
cat > config/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  
  - job_name: 'docker'
    static_configs:
      - targets: ['host.docker.internal:9323']
  
  - job_name: 'traefik'
    static_configs:
      - targets: ['traefik:8080']
  
  - job_name: 'jenkins'
    static_configs:
      - targets: ['jenkins:8080']
EOF

# Configurazione Loki
cat > config/loki.yml << 'EOF'
auth_enabled: false

server:
  http_listen_port: 3100

ingester:
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
    final_sleep: 0s
  chunk_idle_period: 1h
  max_chunk_age: 1h
  chunk_target_size: 1048576
  chunk_retain_period: 30s
  max_transfer_retries: 0

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

storage_config:
  boltdb_shipper:
    active_index_directory: /loki/boltdb-shipper-active
    cache_location: /loki/boltdb-shipper-cache
    shared_store: filesystem
  filesystem:
    directory: /loki/chunks

limits_config:
  reject_old_samples: true
  reject_old_samples_max_age: 168h

chunk_store_config:
  max_look_back_period: 0s

table_manager:
  retention_deletes_enabled: false
  retention_period: 0s
EOF

# Configurazione Grafana
mkdir -p config/grafana/provisioning/{dashboards,datasources}

cat > config/grafana/provisioning/datasources/prometheus.yml << 'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    url: http://prometheus:9090
    access: proxy
    isDefault: true
  
  - name: Loki
    type: loki
    url: http://loki:3100
    access: proxy
EOF

cat > config/grafana/provisioning/dashboards/dashboard.yml << 'EOF'
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /etc/grafana/provisioning/dashboards
EOF

# Configurazione PostgreSQL
cat > config/postgres-init.sql << 'EOF'
-- Database per Gitea
CREATE DATABASE gitea;
CREATE USER gitea WITH PASSWORD 'gitea_password';
GRANT ALL PRIVILEGES ON DATABASE gitea TO gitea;

-- Database per Jenkins (opzionale)
CREATE DATABASE jenkins;
CREATE USER jenkins WITH PASSWORD 'jenkins_password';
GRANT ALL PRIVILEGES ON DATABASE jenkins TO jenkins;
EOF

# Crea file hosts locali
cat > hosts-entries.txt << 'EOF'
# Aggiungi queste righe al tuo file /etc/hosts
127.0.0.1 traefik.homelab.local
127.0.0.1 portainer.homelab.local
127.0.0.1 git.homelab.local
127.0.0.1 jenkins.homelab.local
127.0.0.1 prometheus.homelab.local
127.0.0.1 grafana.homelab.local
127.0.0.1 registry.homelab.local
127.0.0.1 minio.homelab.local
127.0.0.1 minio-api.homelab.local
127.0.0.1 code.homelab.local
127.0.0.1 uptime.homelab.local
127.0.0.1 pihole.homelab.local
EOF

# Crea README con credenziali
cat > README.md << 'EOF'
# DevOps Homelab

## 🚀 Servizi Disponibili

| Servizio | URL | Credenziali |
|----------|-----|-------------|
| Traefik | http://traefik.homelab.local | - |
| Portainer | http://portainer.homelab.local | admin/admin |
| Gitea | http://git.homelab.local | Configurazione iniziale |
| Jenkins | http://jenkins.homelab.local | admin/admin |
| Prometheus | http://prometheus.homelab.local | - |
| Grafana | http://grafana.homelab.local | admin/admin |
| Registry | http://registry.homelab.local | - |
| MinIO | http://minio.homelab.local | admin/admin123456 |
| Code Server | http://code.homelab.local | codeserver123 |
| Uptime Kuma | http://uptime.homelab.local | Configurazione iniziale |
| Pi-hole | http://pihole.homelab.local | admin/pihole123 |

## 🔧 Comandi Utili

```bash
# Avvia tutto
docker compose up -d

# Verifica stato
docker compose ps

# Logs di un servizio
docker compose logs -f [servizio]

# Riavvia un servizio
docker compose restart [servizio]

# Ferma tutto
docker compose down

# Aggiorna immagini
docker compose pull && docker compose up -d
```

## 📋 Setup Iniziale

1. Aggiungi le entry hosts al file /etc/hosts
2. Configura Gitea su http://git.homelab.local
3. Configura Jenkins su http://jenkins.homelab.local
4. Configura Uptime Kuma su http://uptime.homelab.local

## 🎯 Progetti Suggeriti

- CI/CD Pipeline con Jenkins e Gitea
- Monitoring completo con Prometheus/Grafana
- Backup automatico con MinIO
- Sviluppo con Code Server
EOF

echo "✅ Configurazione completata!"
echo "📁 Tutti i file sono nella directory 'homelab'"
echo "📖 Leggi README.md per iniziare"
echo ""
echo "🎯 Prossimi passi:"
echo "1. cd homelab"
echo "2. Aggiungi le entry hosts: sudo nano /etc/hosts"
echo "3. docker compose up -d"
echo "4. Configura i servizi secondo README.md"
