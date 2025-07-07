

# 🚀 DevOps Homelab - Guida per il tuo ambiente multi-stack

Questa guida ti aiuta a configurare e gestire un homelab DevOps moderno, multi-servizio, con stack separati tramite Docker Compose.

## 🗺️ Schema architetturale del sistema

Esempio di architettura su un singolo nodo (Raspberry Pi):

```
┌──────────────────────────────────────────────────────────────┐
│                RASPBERRY PI 4 (UNICO NODO)                   │
│--------------------------------------------------------------│
│  [docker-compose_mng.yml]                                    │
│    - Traefik (proxy/reverse proxy)                           │
│    - Portainer (gestione Docker)                             │
│    - Agent (Portainer)                                       │
│                                                              │
│  [docker-compose_cloud.yml]                                  │
│    - Nextcloud (cloud personale)                             │
│    - Nextcloud DB (MariaDB)                                  │
│    - Paperless (document management)                         │
│    - Paperless DB (Postgres)                                 │
│    - Paperless Redis                                         │
│    - Rhasspy (voice assistant)                               │
│                                                              │
│  [docker-compose_iot.yml]                                    │
│    - Home Assistant (domotica/IoT)                           │
│    - Grafana (dashboard)                                     │
│    - Mosquitto (MQTT broker)                                 │
│    - Zigbee2MQTT                                             │
│    - Node-RED                                                │
│                                                              │
│  [docker-compose_notes.yml]                                  │
│    - Vikunja (task management)                               │
│    - Vikunja DB (Postgres)                                   │
│    - Firefly III (finanze personali)                         │
│    - Firefly III DB (Postgres)                               │
│    - Obsidian LiveSync (note personali)                      │
│                                                              │
│  [docker-compose_network.yml]                                │
│    - Omada Controller (network)                              │
│                                                              │
│  ... (altri container di supporto: backup, ecc.)             │
│                                                              │
│  [ reti Docker: public, private ]                            │
└──────────────────────────────────────────────────────────────┘
                │
                └───── LAN/WiFi ─────┐
                                      │
        ┌──────────────────────────────┘
        │  Accesso da PC, mobile, ecc. │
        └──────────────────────────────┘
```

**Legenda:**
- Tutti i servizi girano su un unico Raspberry Pi.
- Le reti Docker `public` e `private` separano i servizi esposti da quelli interni.
- Traefik gestisce il reverse proxy e l'accesso centralizzato ai servizi.

## 📋 Prerequisiti

- **Hardware**: Raspberry Pi 4 (consigliato 4GB RAM o superiore) oppure qualsiasi server x86/ARM
- **OS**: Ubuntu Server 22.04 LTS (o compatibile)
- **Connessione**: Internet stabile
- **Conoscenze base**: Linux, Docker, terminale

## 📦 Struttura del Progetto

Questa repository contiene diversi file Compose, ognuno per uno stack tematico:

- `docker-compose_cloud.yml`   → Cloud personale (Nextcloud, Paperless, Rhasspy)
- `docker-compose_iot.yml`     → IoT & automazione (Home Assistant, Grafana, Mosquitto, Zigbee2MQTT, Node-RED, ecc.)
- `docker-compose_mng.yml`     → Management (Portainer, agent)
- `docker-compose_network.yml` → Network (Omada Controller)
- `docker-compose_notes.yml`   → Note, task, finanze (Obsidian LiveSync, Vikunja, Firefly III)

> **Nota:** Ogni file può essere avviato singolarmente o in combinazione, a seconda delle tue esigenze.

## 🛠️ Setup iniziale

### 1. Prepara il sistema

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git vim htop net-tools
```

### 2. Installa Docker e Docker Compose

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
sudo apt install -y docker-compose-plugin
sudo reboot
```

### 3. Verifica installazione

```bash
docker --version
docker compose version
docker run hello-world
```

### 4. Prepara directory di lavoro

```bash
mkdir -p ~/homelab/{config,data,projects}
cd ~/homelab
```

### 5. Configura DNS locale (opzionale ma consigliato)

Aggiungi queste righe al file `/etc/hosts` del tuo computer (sostituisci IP_RASPBERRY con l'IP del tuo server):

```
IP_RASPBERRY traefik.homelab.local
IP_RASPBERRY portainer.homelab.local
IP_RASPBERRY cloud.homelab.local
IP_RASPBERRY docs.homelab.local
IP_RASPBERRY voice.homelab.local
IP_RASPBERRY hass.homelab.local
IP_RASPBERRY iot-stats.homelab.local
IP_RASPBERRY tasks.homelab.local
IP_RASPBERRY finance.homelab.local
IP_RASPBERRY notes.homelab.local
IP_RASPBERRY omada.homelab.local
```

## ⚙️ Configurazione

### 1. File delle variabili d'ambiente

Crea un file `.env` nella root del progetto con tutte le variabili richieste dai compose file. Esempio:

```env
STACK=homelab
DOMAIN=homelab.local
NEXTCLOUD_DB_PASS=superpassword
NEXTCLOUD_ADMIN=admin
NEXTCLOUD_ADMIN_PASS=superpassword
MYSQL_ROOT_PASS=superpassword
TZ=Europe/Rome
PAPERLESS_SECRET=secretkey
GRAFANA_ADMIN_PASS=admin
AGENT_TOKEN=token
OBSIDIAN_USER=utente
OBSIDIAN_PASS=password
VIKUNJA_DB_PASS=vikunja_pass
VIKUNJA_JWT_SECRET=jwt_secret
FIREFLY_APP_KEY=firefly_key
FIREFLY_DB_PASS=firefly_pass
FIREFLY_ADMIN_EMAIL=mail@example.com
```
Adatta i valori alle tue esigenze.

### 2. Prepara file SSL (se usi Traefik con HTTPS)

```bash
mkdir -p ~/homelab/data
touch ~/homelab/data/acme.json
chmod 600 ~/homelab/data/acme.json
```

### 3. (Opzionale) Prepara file di configurazione custom (es. traefik.yml, prometheus.yml, ecc.)

## 🚀 Deploy degli stack

### 1. Crea le network Docker condivise (se richiesto dai compose)

```bash
docker network create public || true
docker network create private || true
```

### 2. Avvia uno o più stack

Esempio per avviare lo stack cloud:

```bash
docker compose -f docker-compose_cloud.yml up -d
```

Per avviare più stack insieme:

```bash
docker compose -f docker-compose_cloud.yml -f docker-compose_iot.yml up -d
```

Per vedere lo stato dei servizi:

```bash
docker compose -f docker-compose_cloud.yml ps
```

Per vedere i log:

```bash
docker compose -f docker-compose_cloud.yml logs -f
```

## 🖥️ Servizi principali e URL

| Servizio            | URL                                 | Compose file                | Note/Utente                |
|---------------------|-------------------------------------|-----------------------------|----------------------------|
| Traefik Dashboard   | http://traefik.${DOMAIN}            | Tutti (proxy)               |                            |
| Portainer           | http://portainer.${DOMAIN}          | docker-compose_mng.yml      | admin / scegli password    |
| Nextcloud           | http://cloud.${DOMAIN}              | docker-compose_cloud.yml    | ${NEXTCLOUD_ADMIN}         |
| Paperless           | http://docs.${DOMAIN}               | docker-compose_cloud.yml    |                            |
| Rhasspy             | http://voice.${DOMAIN}:12101        | docker-compose_cloud.yml    |                            |
| Home Assistant      | http://hass.${DOMAIN}:8123          | docker-compose_iot.yml      |                            |
| Grafana             | http://iot-stats.${DOMAIN}:3000     | docker-compose_iot.yml      | admin / ${GRAFANA_ADMIN_PASS} |
| Vikunja             | http://tasks.${DOMAIN}              | docker-compose_notes.yml    | admin / setup              |
| Firefly III         | http://finance.${DOMAIN}            | docker-compose_notes.yml    | setup                      |
| Obsidian LiveSync   | http://notes.${DOMAIN}:3000         | docker-compose_notes.yml    | ${OBSIDIAN_USER}           |
| Omada Controller    | http://<IP>:8088                    | docker-compose_network.yml  |                            |

> Sostituisci `${DOMAIN}` con il dominio scelto nel file `.env` (es: homelab.local).

## 🔧 Gestione e manutenzione

### Comandi utili

```bash
# Stato stack
docker compose -f docker-compose_cloud.yml ps

# Riavvia servizio
docker compose -f docker-compose_cloud.yml restart <servizio>

# Aggiorna immagini
docker compose -f docker-compose_cloud.yml pull
docker compose -f docker-compose_cloud.yml up -d

# Backup volumi (esempio Nextcloud)
docker run --rm -v devops-homelab_nextcloud_data:/data -v $(pwd):/backup alpine tar czf /backup/nextcloud-backup.tar.gz /data

# Pulizia sistema
docker system prune -a
```

### Monitoraggio risorse

```bash
htop
df -h
docker stats
```

## 🔒 Sicurezza

1. Cambia tutte le password di default
2. Configura SSL con Let's Encrypt se esposto su Internet
3. Limita l’accesso alle reti private
4. Fai backup regolari dei volumi
5. Aggiorna regolarmente le immagini

## 🚨 Troubleshooting

```bash
# Logs servizio
docker compose -f <compose-file> logs <servizio>

# Stato risorse
free -h
df -h
docker stats

# Verifica network
docker network inspect public
docker network inspect private

# Verifica DNS
nslookup traefik.${DOMAIN}
```

## 📚 Risorse utili

- [Documentazione Docker](https://docs.docker.com/)
- [Traefik Docs](https://doc.traefik.io/traefik/)
- [Grafana Docs](https://grafana.com/docs/)
- [Home Assistant Docs](https://www.home-assistant.io/docs/)
- [Paperless-ngx Docs](https://paperless-ngx.readthedocs.io/)
- [Vikunja Docs](https://vikunja.io/docs/)
- [Firefly III Docs](https://docs.firefly-iii.org/)
- [Obsidian LiveSync](https://github.com/vrtmrz/obsidian-livesync)

---

**🎉 Il tuo DevOps Homelab multi-stack è pronto!**

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
In questa repository troverai diversi file Compose, ognuno per uno stack specifico:

- `docker-compose_cloud.yml`
- `docker-compose_iot.yml`
- `docker-compose_mng.yml`
- `docker-compose_network.yml`
- `docker-compose_notes.yml`

> **Nota:** I file sono già pronti all'uso, non serve crearli manualmente.

> **Importante:** Nei file Compose recenti il campo `version` non è più necessario e può essere rimosso.

### Step 5: Preparazione File SSL
```bash
# Crea file per certificati SSL
touch ~/homelab/data/acme.json
chmod 600 ~/homelab/data/acme.json
```

### Step 6: File delle variabili d'ambiente
Per evitare warning all'avvio, crea un file `.env` nella root del progetto con tutte le variabili richieste dai compose file. Esempio:

```env
STACK=homelab
DOMAIN=homelab.local
NEXTCLOUD_DB_PASS=superpassword
NEXTCLOUD_ADMIN=admin
NEXTCLOUD_ADMIN_PASS=superpassword
MYSQL_ROOT_PASS=superpassword
TZ=Europe/Rome
PAPERLESS_SECRET=secretkey
GRAFANA_ADMIN_PASS=admin
AGENT_TOKEN=token
OBSIDIAN_USER=utente
OBSIDIAN_PASS=password
VIKUNJA_DB_PASS=vikunja_pass
VIKUNJA_JWT_SECRET=jwt_secret
FIREFLY_APP_KEY=firefly_key
FIREFLY_DB_PASS=firefly_pass
FIREFLY_ADMIN_EMAIL=mail@example.com
```
Adatta i valori alle tue esigenze.

## 🚀 FASE 3: Deploy dell'Ambiente

### Step 1: Creazione Network
```bash
cd ~/homelab

# Crea network Docker condivisa
docker network create homelab
```

### Step 2: Avvio Servizi
```bash
# Avvia uno stack specifico (esempio: cloud)
docker compose -f docker-compose_cloud.yml up -d

# Oppure avvia più stack
docker compose -f docker-compose_cloud.yml -f docker-compose_iot.yml up -d

# Verifica stato servizi
docker compose -f docker-compose_cloud.yml ps

# Verifica logs
docker compose -f docker-compose_cloud.yml logs -f
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
- **URL**: http://portainer.${DOMAIN}
- **Setup**: Crea account admin alla prima visita
- **Username**: admin
- **Password**: scegli una password sicura
- **Avvio**: `docker compose -f docker-compose_mng.yml up -d`

### 3. Nextcloud (Cloud personale)
- **URL**: http://cloud.${DOMAIN}
- **Username**: ${NEXTCLOUD_ADMIN}
- **Password**: ${NEXTCLOUD_ADMIN_PASS}
- **Avvio**: `docker compose -f docker-compose_cloud.yml up -d`

### 4. Paperless (Document Management)
- **URL**: http://docs.${DOMAIN}
- **Avvio**: `docker compose -f docker-compose_cloud.yml up -d`

### 5. Rhasspy (Voice Assistant)
- **URL**: http://voice.${DOMAIN}:12101
- **Avvio**: `docker compose -f docker-compose_cloud.yml up -d`

### 6. Home Assistant & IoT
- **URL**: http://hass.${DOMAIN}:8123
- **Avvio**: `docker compose -f docker-compose_iot.yml up -d`

### 7. Grafana
- **URL**: http://iot-stats.${DOMAIN}:3000
- **Username**: admin
- **Password**: ${GRAFANA_ADMIN_PASS}
- **Avvio**: `docker compose -f docker-compose_iot.yml up -d`

### 8. Vikunja (Task Management)
- **URL**: http://tasks.${DOMAIN}
- **Username**: admin
- **Password**: impostato in fase di setup
- **Avvio**: `docker compose -f docker-compose_notes.yml up -d`

### 9. Firefly III (Finanze personali)
- **URL**: http://finance.${DOMAIN}
- **Username**: impostato in fase di setup
- **Password**: impostato in fase di setup
- **Avvio**: `docker compose -f docker-compose_notes.yml up -d`

### 10. Obsidian LiveSync (Note personali)
- **URL**: http://notes.${DOMAIN}:3000
- **Username**: ${OBSIDIAN_USER}
- **Password**: ${OBSIDIAN_PASS}
- **Avvio**: `docker compose -f docker-compose_notes.yml up -d`

### 11. Omada Controller (Network)
- **URL**: http://<IP>:8088 (o porta configurata)
- **Avvio**: `docker compose -f docker-compose_network.yml up -d`

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
docker compose -f docker-compose_cloud.yml ps

# Riavvia servizio specifico
docker compose -f docker-compose_cloud.yml restart [servizio]

# Aggiorna immagini
docker compose -f docker-compose_cloud.yml pull
docker compose -f docker-compose_cloud.yml up -d

# Backup volumi
docker run --rm -v devops-homelab_gitea_data:/data -v $(pwd):/backup alpine tar czf /backup/gitea-backup.tar.gz /data

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
