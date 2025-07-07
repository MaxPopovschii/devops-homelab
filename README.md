# 🚀 DevOps Homelab - Guida Completa

Una guida completa per creare un ambiente DevOps professionale con Raspberry Pi 4 e Ubuntu Server.

## 📋 Prerequisiti

- **Hardware**: Raspberry Pi 4 (4GB RAM consigliati)
- **OS**: Ubuntu Server 22.04 LTS
- **Connessione**: Internet stabile
- **Conoscenze base**: Linux, Docker, terminale

## 🎯 Architettura del Sistema

```
┌─────────────────────────────────────────────────────────────┐
│                    RASPBERRY PI 4                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   TRAEFIK   │  │  PORTAINER  │  │   GITEA     │         │
│  │ (Proxy)     │  │ (Docker UI) │  │ (Git)       │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   JENKINS   │  │ PROMETHEUS  │  │   GRAFANA   │         │
│  │ (CI/CD)     │  │ (Metrics)   │  │ (Dashboard) │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │    MINIO    │  │   PIHOLE    │  │ CODE-SERVER │         │
│  │ (Storage)   │  │ (DNS)       │  │ (IDE)       │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

## 🔧 FASE 1: Preparazione Sistema

### Step 1: Accesso e Aggiornamento
```bash
# Connettiti al Raspberry Pi
ssh ubuntu@IP_RASPBERRY

# Aggiorna il sistema
sudo apt update && sudo apt upgrade -y

# Installa pacchetti essenziali
sudo apt install -y curl wget git vim htop net-tools
```

### Step 2: Installazione Docker
```bash
# Scarica e installa Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Aggiungi utente al gruppo docker
sudo usermod -aG docker $USER

# Installa Docker Compose
sudo apt install -y docker-compose-plugin

# Riavvia per applicare le modifiche
sudo reboot
```

### Step 3: Verifica Installazione
```bash
# Dopo il riboot, testa Docker
docker --version
docker compose version
docker run hello-world
```

## 🏗️ FASE 2: Configurazione Homelab

### Step 1: Creazione Struttura Directory
```bash
# Crea directory principale
mkdir -p ~/homelab/{config,data,projects}
cd ~/homelab

# Verifica struttura
tree ~/homelab
```

### Step 2: Configurazione DNS Locale
```bash
# Modifica file hosts (sul tuo computer, non sul Pi)
sudo nano /etc/hosts

# Aggiungi queste righe (sostituisci IP_RASPBERRY con l'IP del tuo Pi)
IP_RASPBERRY traefik.homelab.local
IP_RASPBERRY portainer.homelab.local
IP_RASPBERRY git.homelab.local
IP_RASPBERRY jenkins.homelab.local
IP_RASPBERRY prometheus.homelab.local
IP_RASPBERRY grafana.homelab.local
IP_RASPBERRY registry.homelab.local
IP_RASPBERRY minio.homelab.local
IP_RASPBERRY minio-api.homelab.local
IP_RASPBERRY code.homelab.local
IP_RASPBERRY uptime.homelab.local
IP_RASPBERRY pihole.homelab.local
```

### Step 3: Creazione File di Configurazione

#### Traefik Configuration
```bash
# Crea file di configurazione Traefik
cat > ~/homelab/config/traefik.yml << 'EOF'
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
```

#### Prometheus Configuration
```bash
cat > ~/homelab/config/prometheus.yml << 'EOF'
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
```

#### Loki Configuration
```bash
cat > ~/homelab/config/loki.yml << 'EOF'
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
```

#### Grafana Provisioning
```bash
# Crea directory per Grafana
mkdir -p ~/homelab/config/grafana/provisioning/{dashboards,datasources}

# Datasources
cat > ~/homelab/config/grafana/provisioning/datasources/prometheus.yml << 'EOF'
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

# Dashboards
cat > ~/homelab/config/grafana/provisioning/dashboards/dashboard.yml << 'EOF'
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
```

#### PostgreSQL Init Script
```bash
cat > ~/homelab/config/postgres-init.sql << 'EOF'
-- Database per Gitea
CREATE DATABASE gitea;
CREATE USER gitea WITH PASSWORD 'gitea_password';
GRANT ALL PRIVILEGES ON DATABASE gitea TO gitea;

-- Database per Jenkins (opzionale)
CREATE DATABASE jenkins;
CREATE USER jenkins WITH PASSWORD 'jenkins_password';
GRANT ALL PRIVILEGES ON DATABASE jenkins TO jenkins;
EOF
```

### Step 4: Preparazione File Docker Compose
```bash
# Crea il file docker-compose.yml
nano ~/homelab/docker-compose.yml

# Copia e incolla il contenuto del docker-compose.yml fornito
```

### Step 5: Preparazione File SSL
```bash
# Crea file per certificati SSL
touch ~/homelab/data/acme.json
chmod 600 ~/homelab/data/acme.json
```

## 🚀 FASE 3: Deploy dell'Ambiente

### Step 1: Creazione Network
```bash
cd ~/homelab

# Crea network Docker condivisa
docker network create homelab
```

### Step 2: Avvio Servizi
```bash
# Avvia tutti i servizi
docker compose up -d

# Verifica stato servizi
docker compose ps

# Verifica logs
docker compose logs -f
```

### Step 3: Verifica Deployments
```bash
# Controlla che tutti i container siano running
docker ps

# Verifica network
docker network ls

# Controlla volumi
docker volume ls
```

## 🎯 FASE 4: Configurazione Servizi

### 1. Traefik Dashboard
- **URL**: http://traefik.homelab.local
- **Note**: Dovrebbe essere accessibile immediatamente

### 2. Portainer Setup
- **URL**: http://portainer.homelab.local
- **Setup**: Crea account admin alla prima visita
- **Username**: admin
- **Password**: scegli una password sicura

### 3. Gitea Configuration
- **URL**: http://git.homelab.local
- **Database**: PostgreSQL
- **Host**: postgres:5432
- **Username**: gitea
- **Password**: gitea_password
- **Database Name**: gitea

### 4. Jenkins Setup
- **URL**: http://jenkins.homelab.local
- **Initial Password**: 
```bash
# Ottieni password iniziale
docker compose exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

### 5. Grafana Configuration
- **URL**: http://grafana.homelab.local
- **Username**: admin
- **Password**: admin
- **Note**: Prometheus è già configurato come datasource

### 6. MinIO Setup
- **URL**: http://minio.homelab.local
- **Username**: admin
- **Password**: admin123456

### 7. Code Server
- **URL**: http://code.homelab.local
- **Password**: codeserver123

### 8. Pi-hole Configuration
- **URL**: http://pihole.homelab.local
- **Password**: pihole123

## 📊 Monitoraggio e Logging

### Prometheus Targets
Verifica che tutti i target siano UP:
- http://prometheus.homelab.local/targets

### Grafana Dashboards
Importa dashboards utili:
- Docker Dashboard (ID: 893)
- Node Exporter (ID: 1860)
- Traefik Dashboard (ID: 4475)

### Uptime Kuma
- **URL**: http://uptime.homelab.local
- Configura monitoring per tutti i servizi

## 🔧 Gestione e Manutenzione

### Comandi Utili
```bash
# Verifica stato
docker compose ps

# Riavvia servizio specifico
docker compose restart [servizio]

# Aggiorna immagini
docker compose pull
docker compose up -d

# Backup volumi
docker run --rm -v homelab_gitea_data:/data -v $(pwd):/backup alpine tar czf /backup/gitea-backup.tar.gz /data

# Pulizia sistema
docker system prune -a
```

### Monitoraggio Risorse
```bash
# Utilizzo CPU/RAM
htop

# Spazio disco
df -h

# Stato container
docker stats
```

## 🔒 Sicurezza

### Configurazioni Raccomandate
1. **Cambia password default** di tutti i servizi
2. **Configura SSL** con Let's Encrypt
3. **Limita accesso network** se necessario
4. **Backup regolari** dei volumi importanti
5. **Aggiorna regolarmente** le immagini

### Backup Script
```bash
#!/bin/bash
# backup-homelab.sh
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/home/ubuntu/backups"

mkdir -p $BACKUP_DIR

# Backup volumi importanti
docker run --rm -v homelab_gitea_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/gitea-$DATE.tar.gz /data
docker run --rm -v homelab_jenkins_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/jenkins-$DATE.tar.gz /data
docker run --rm -v homelab_grafana_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/grafana-$DATE.tar.gz /data
```

## 🚨 Troubleshooting

### Problemi Comuni

#### Container non si avvia
```bash
# Verifica logs
docker compose logs [servizio]

# Verifica risorse
free -h
df -h
```

#### Servizio non raggiungibile
```bash
# Verifica network
docker network inspect homelab

# Verifica DNS
nslookup traefik.homelab.local
```

#### Performance lente
```bash
# Verifica utilizzo risorse
docker stats

# Libera spazio
docker system prune -a
```

## 🎓 Progetti Pratici

### 1. Pipeline CI/CD Completa
1. Crea repository in Gitea
2. Configura webhook per Jenkins
3. Scrivi Jenkinsfile per build/test/deploy
4. Deploy su registro Docker locale

### 2. Monitoring Completo
1. Configura Node Exporter
2. Crea dashboard custom in Grafana
3. Configura alerting con Prometheus
4. Integra con Uptime Kuma

### 3. Sviluppo Remoto
1. Usa Code Server per development
2. Integra con Gitea per version control
3. Usa MinIO per storage files
4. Deploy automatico con Jenkins

## 📚 Risorse Aggiuntive

- [Documentazione Docker](https://docs.docker.com/)
- [Traefik Docs](https://doc.traefik.io/traefik/)
- [Prometheus Docs](https://prometheus.io/docs/)
- [Grafana Docs](https://grafana.com/docs/)
- [Jenkins Docs](https://www.jenkins.io/doc/)

## 🆘 Supporto

Se incontri problemi:
1. Verifica i logs: `docker compose logs [servizio]`
2. Controlla la documentazione del servizio specifico
3. Verifica le configurazioni di rete
4. Assicurati che le porte non siano in conflitto

---

## 📋 Checklist Finale

- [ ] Sistema base aggiornato
- [ ] Docker installato e funzionante
- [ ] Directory homelab creata
- [ ] File di configurazione creati
- [ ] DNS locale configurato
- [ ] Docker Compose deployato
- [ ] Tutti i servizi accessibili
- [ ] Servizi configurati inizialmente
- [ ] Backup configurato
- [ ] Monitoraggio attivo

**🎉 Congratulazioni! Il tuo DevOps Homelab è pronto!**
