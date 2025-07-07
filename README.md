

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


| Servizio                | URL                                      | Porta/Path         | Compose file                | Note/Utente                |
|-------------------------|------------------------------------------|--------------------|-----------------------------|----------------------------|
| Traefik Dashboard       | http://traefik.${DOMAIN}                 | 80                 | docker-compose_mng.yml      | Reverse proxy, dashboard   |
| Portainer               | http://portainer.${DOMAIN}               | 9000               | docker-compose_mng.yml      | admin / scegli password    |
| Agent (Portainer)       | -                                        | 9001 (interno)     | docker-compose_mng.yml      |                            |
| Nextcloud               | http://cloud.${DOMAIN}                   | 80                 | docker-compose_cloud.yml    | ${NEXTCLOUD_ADMIN}         |
| Nextcloud DB            | -                                        | 3306 (interno)     | docker-compose_cloud.yml    | MariaDB                    |
| Paperless               | http://docs.${DOMAIN}                    | 8000               | docker-compose_cloud.yml    |                            |
| Paperless DB            | -                                        | 5432 (interno)     | docker-compose_cloud.yml    | Postgres                   |
| Paperless Redis         | -                                        | 6379 (interno)     | docker-compose_cloud.yml    | Redis                      |
| Rhasspy                 | http://voice.${DOMAIN}:12101             | 12101              | docker-compose_cloud.yml    |                            |
| Home Assistant          | http://hass.${DOMAIN}:8123               | 8123               | docker-compose_iot.yml      |                            |
| Grafana                 | http://iot-stats.${DOMAIN}:3000          | 3000               | docker-compose_iot.yml      | admin / ${GRAFANA_ADMIN_PASS} |
| Mosquitto               | mqtt://${DOMAIN}:1883                    | 1883               | docker-compose_iot.yml      | MQTT broker                |
| Zigbee2MQTT             | -                                        | 8080 (web), 1883   | docker-compose_iot.yml      |                            |
| Node-RED                | http://automation.${DOMAIN}:1880         | 1880               | docker-compose_iot.yml      |                            |
| Vikunja                 | http://tasks.${DOMAIN}                   | 3456               | docker-compose_notes.yml    | admin / setup              |
| Vikunja DB              | -                                        | 5432 (interno)     | docker-compose_notes.yml    | Postgres                   |
| Firefly III             | http://finance.${DOMAIN}                 | 8080               | docker-compose_notes.yml    | setup                      |
| Firefly III DB          | -                                        | 5432 (interno)     | docker-compose_notes.yml    | Postgres                   |
| Obsidian LiveSync       | http://notes.${DOMAIN}:3000              | 3000               | docker-compose_notes.yml    | ${OBSIDIAN_USER}           |
| Omada Controller        | http://<IP>:8088                         | 8088, 8043, ...    | docker-compose_network.yml  | TP-Link Omada              |


> Sostituisci `${DOMAIN}` con il dominio scelto nel file `.env` (es: homelab.local). I servizi DB e Redis sono accessibili solo internamente ai container.

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

ingester:
schema_config:
storage_config:
datasources:


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
