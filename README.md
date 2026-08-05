# 🌦️ AClimate v3 Platform

Docker Compose orchestration for the AClimate v3 ecosystem. Launches the API, Frontend, Keycloak, GeoServer, databases, and monitoring with **a single command** — with persistence and auto-generated URLs.

```
┌─────────────────┐     ┌──────────────────┐     ┌──────────────┐
│   db_keycloak   │     │   db_aclimate    │     │  geoserver   │
│  postgres:16-   │     │ postgis/postgis  │     │  2.25.2      │
│  alpine         │     │ :16-3.4          │     │  port: 8600  │
│  port: 5433     │     │ port: 5432       │     └──────┬───────┘
└────────┬────────┘     └────────┬─────────┘            │
         │                       │                      │
         ▼                       ▼                      │
┌─────────────────┐     ┌──────────────────┐            │
│    keycloak     │◄────│     webapi       │◄───────────┘
│  26.0.7         │     │  GHCR image      │
│  port: 8080     │     │  port: 3002      │
└────────┬────────┘     └────────┬─────────┘
         │                       │
         └───────────┬───────────┘        ┌──────────────┐
                     ▼                    │  users-api   │
            ┌──────────────────┐          │   port:3004  │
            │    frontend      │          └──────┬───────┘
            │   Clone GitHub   │                 │
            │   port: 3000     │                 ▼
            └──────────────────┘         ┌──────────────────┐
                                         │      admin       │
                                         │   port: 3003     │
                                         └──────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                    MONITORING (optional)                      │
│  prometheus:9090  grafana:3001  loki:3100  blackbox:9115      │
└──────────────────────────────────────────────────────────────┘
```

**13 services**, including:

- **API**: `ghcr.io/ciat-dapa/aclimate_v3_webapi` ([repo](https://github.com/CIAT-DAPA/aclimate_v3_webapi))
- **Frontend**: auto-cloned from `aclimate_v3_frontend` ([repo](https://github.com/CIAT-DAPA/aclimate_v3_frontend)) — no local clone needed
- **Admin**: local build from `aclimate_v3_admin` ([repo](https://github.com/CIAT-DAPA/aclimate_v3_admin))
- **Users API**: `ghcr.io/ciat-dapa/aclimate_v3_frontend_users_webapi` ([repo](https://github.com/CIAT-DAPA/aclimate_v3_frontend_users_webapi)) — user preferences/stations backend
- **Keycloak** + **GeoServer** + **2x PostgreSQL (PostGIS)**
- **Monitoring**: Prometheus, Grafana, Loki, Promtail, Blackbox exporter

---

## 📌 Prerequisites

- Docker Engine 24+ with Compose plugin
- Access to `ghcr.io` for the API image

> The frontend is **auto-cloned from GitHub** during the Docker build (see `bootstrap/frontend/Dockerfile`) — no local clone required.

---

## 🚀 Quick Start (3 steps)

### 1. Configure the environment

```bash
cp .env.example .env
```

No editing needed for local development — the defaults already point to the correct services.

### 2. Start the stack (with local databases)

```bash
docker compose --profile db up -d
```

> The **first start** takes a few minutes (downloads ~2GB of images and compiles the frontend). Subsequent starts are fast.

### 3. Verify

```bash
docker compose ps                # all must be (healthy)

curl http://localhost:3002/health    # WebAPI  → {"status":"ok"}
# Browse to:
#   http://localhost:3000          Frontend
#   http://localhost:8080          Keycloak Admin (admin/admin)
#   http://localhost:8600/geoserver  GeoServer
#   http://localhost:3002/docs     API Swagger
```

---

## 🌱 How URLs are auto-generated

**No full URLs are passed as variables.** The compose file builds them at build time from just 4 configurable ports:

```ini
# In .env — the only lines that control ports
KEYCLOAK_PORT=8080
GEOSERVER_PORT=8600
WEBAPI_PORT=3002
FRONTEND_PORT=3000
```

| Generated variable             | Source                                                                                          | Used by              |
| ------------------------------ | ----------------------------------------------------------------------------------------------- | -------------------- |
| `NEXT_PUBLIC_KEYCLOAK_URL`     | `http://localhost:${KEYCLOAK_PORT}`                                                             | Frontend (build arg) |
| `NEXT_PUBLIC_ACLIMATE_API_URL` | `http://localhost:${WEBAPI_PORT}`                                                               | Frontend (build arg) |
| `NEXT_PUBLIC_AUTH_API_URL`     | `http://localhost:${WEBAPI_PORT}/api`                                                           | Frontend (build arg) |
| `NEXT_PUBLIC_GEOSERVER_URL`    | `http://localhost:${GEOSERVER_PORT}/geoserver`                                                  | Frontend (build arg) |
| `KEYCLOAK_URL`                 | `http://keycloak:8080` (internal DNS, fixed)                                                    | WebAPI               |
| `GEOSERVER_URL`                | `http://geoserver:8080/geoserver/` (internal DNS, fixed)                                        | WebAPI               |
| `DATABASE_URL`                 | `postgresql://${ACLIMATE_DB_USER}:${ACLIMATE_DB_PASSWORD}@db_aclimate:5432/${ACLIMATE_DB_NAME}` | WebAPI               |

**Example**: if you want Keycloak to run on port 9090 on your machine:

```ini
KEYCLOAK_PORT=9090
```

The frontend is automatically rebuilt with `NEXT_PUBLIC_KEYCLOAK_URL=http://localhost:9090` — no other URL needs touching.

> **Internal** URLs (WebAPI → Keycloak/GeoServer) never change because they use Docker DNS (`keycloak:8080`, `geoserver:8080`), which is independent of the host-exposed ports.

---

## 🗄️ Environment Variables

### External ports (change to remap host ports)

| Variable         | Default | Purpose                                                  |
| ---------------- | ------- | -------------------------------------------------------- |
| `KEYCLOAK_PORT`  | `8080`  | Host port for Keycloak                                   |
| `GEOSERVER_PORT` | `8600`  | Host port for GeoServer (avoids collision with Keycloak) |
| `WEBAPI_PORT`    | `3002`  | Host port for the WebAPI                                 |
| `FRONTEND_PORT`  | `3000`  | Host port for the Frontend                               |

### WebAPI (same names as `src/.env` in its repo)

| Variable             | Default                      | Purpose                                   |
| -------------------- | ---------------------------- | ----------------------------------------- |
| `REALM_NAME`         | `aclimate`                   | Keycloak realm                            |
| `CLIENT_ID`          | `aclimate_frontend_honduras` | Keycloak client                           |
| `CLIENT_SECRET`      | _(sensitive)_                | Client secret                             |
| `GEOSERVER_USER`     | `scalderon`                  | GeoServer user                            |
| `GEOSERVER_PASSWORD` | _(sensitive)_                | GeoServer password                        |
| `MAX_WORKERS`        | `4`                          | uvicorn workers                           |
| `MAX_SYNC_DAYS`      | `7`                          | Sync days                                 |
| `HEALTH_TOKEN`       | _(empty)_                    | Protects `/health` and `/ready` endpoints |

### Frontend (same names as `src/.env` in its repo)

| Variable                                | Default                      | Purpose                                    |
| --------------------------------------- | ---------------------------- | ------------------------------------------ |
| `NEXT_PUBLIC_KEYCLOAK_REALM`            | `aclimate`                   | Realm                                      |
| `NEXT_PUBLIC_KEYCLOAK_CLIENT_ID`        | `aclimate_frontend_honduras` | Client ID                                  |
| `NEXT_PUBLIC_ACLIMATE_APP_ID`           | `4`                          | App ID                                     |
| `NEXT_PUBLIC_COUNTRY_NAME`              | `El Salvador`                | Country                                    |
| `NEXT_PUBLIC_SHOW_STATIONS_MODULE`      | `true`                       | Show stations                              |
| `NEXT_PUBLIC_SHOW_USERS_MODULE`         | `false`                      | Show users                                 |
| `NEXT_PUBLIC_FORECAST_API_URL`          | _(external)_                 | Forecast API                               |
| `NEXT_PUBLIC_ACLIMATE_API_FRONTEND_URL` | _(external)_                 | User preferences API                       |
| `NEXT_PUBLIC_BASE_PATH`                 | _(empty)_                    | Deployment subpath (e.g. `/ahuachapansur`) |
| `KEYCLOAK_CLIENT_SECRET`                | _(sensitive)_                | Frontend runtime secret                    |

---

## 🗄️ Database — Bootstrap and dumps

The `aclimate` database is restored automatically on the **first start** (empty volume). The restore script (`bootstrap/db/init/02-restore-dump.sh`) **finds any `*.dump` file** in `bootstrap/db/dumps/` — the name does not matter:

```
bootstrap/db/dumps/       ← put any .dump file here (e.g. aclimate_pg_20260804.dump)
```

**Dumps are NOT committed to git** (see `.gitignore`). To restore from your local dump:

```bash
# 1. Copy your dump (any name works)
copy C:\Users\YOUR_USER\Downloads\aclimate_pg_20260804.dump bootstrap\db\dumps\

# 2. If you already started the stack before, wipe the data volume:
docker compose down -v

# 3. Start again (automatic detect + restore)
docker compose --profile db up -d
```

| DB Service    | Image                    | Host port | Database      | User/Password                |
| ------------- | ------------------------ | --------- | ------------- | ---------------------------- |
| `db_aclimate` | `postgis/postgis:16-3.4` | 5432      | `aclimate_db` | `postgres` / `admin`         |
| `db_keycloak` | `postgres:16-alpine`     | 5433      | `keycloak`    | `keycloak` / `keycloak_pass` |

---

## 🧩 Compose Profiles

| Profile      | Services                              | Use                                |
| ------------ | ------------------------------------- | ---------------------------------- |
| (none)       | keycloak, geoserver, webapi, frontend | External DBs (RDS, Cloud SQL)      |
| `db`         | + db_keycloak, db_aclimate            | Local development with bundled DBs |
| `monitoring` | + prometheus, grafana, loki, promtail | Metrics & logs observability       |

### Use external databases

If you already have Postgres/PostGIS in the cloud, edit `.env`:

```ini
ACLIMATE_DB_USER=your_user
ACLIMATE_DB_PASSWORD=your_password
ACLIMATE_DB_NAME=your_db
```

> Note: with external DBs, `DATABASE_URL` is generated pointing to the external host. Edit the host in `compose.yaml` under `DATABASE_URL` accordingly.

And start **without** the `db` profile:

```bash
docker compose up -d
```

---

## 📈 Monitoring (Grafana + Prometheus + Loki + Exporters)

The full observability stack runs inside Compose with the `monitoring` profile:

```bash
docker compose --profile db --profile monitoring up -d
```

| Service           | URL                   | Credentials | Purpose                                  |
| ----------------- | --------------------- | ----------- | ---------------------------------------- |
| Grafana           | http://localhost:3001 | admin/admin | Dashboards and log explorer              |
| Prometheus        | http://localhost:9090 | —           | Metrics storage & scraping               |
| Loki              | http://localhost:3100 | —           | Log aggregation backend                  |
| Promtail          | —                     | —           | Collects container logs → Loki           |
| Blackbox exporter | http://localhost:9115 | —           | Probes health endpoints of every service |
| Node Exporter     | http://localhost:9100 | —           | Host metrics (CPU, RAM, disk, network)   |
| cAdvisor          | http://localhost:8081 | —           | Per-container metrics (CPU, RAM, I/O)    |
| PostgreSQL Exp.   | http://localhost:9187 | —           | Database metrics (connections, locks)    |

### What is monitored

| Data                                                                | Source                                  |
| ------------------------------------------------------------------- | --------------------------------------- |
| Uptime + latency of WebAPI, Frontend, Keycloak, GeoServer           | Blackbox → Prometheus (`probe_success`) |
| Keycloak JVM, HTTP requests, threads, errors                        | Keycloak `/metrics` → Prometheus        |
| Host CPU, RAM, disk, network, uptime                                | Node Exporter → Prometheus              |
| Per-container CPU, RAM, network I/O, restarts                       | cAdvisor → Prometheus                   |
| PostgreSQL connections, locks, deadlocks, WAL, size                 | postgres-exporter → Prometheus          |
| Logs of **all** containers (with labels: container, service, image) | Promtail → Loki                         |

### Dashboards (auto-provisioned, organized by folder)

| Folder             | Dashboard                    | Source            |
| ------------------ | ---------------------------- | ----------------- |
| **Infrastructure** | Node Exporter Full           | Prometheus        |
| **Infrastructure** | Docker Containers (cAdvisor) | Prometheus        |
| **Application**    | AClimate Overview            | Prometheus + Loki |
| **Application**    | Service Status (Blackbox)    | Prometheus        |
| **Database**       | PostgreSQL Overview          | Prometheus        |
| **Authentication** | Keycloak Overview            | Prometheus        |
| **Logs**           | Container Logs (Loki)        | Loki              |

Dashboards are auto-provisioned from `config/grafana/dashboards/` on first start.
To query logs interactively: Grafana → **Explore** (compass icon) → datasource **Loki** → `{container=~"aclimate.*"}`.

---

## 💾 Volumes and persistence

| Volume             | Service     | Path                        | Critical data                      |
| ------------------ | ----------- | --------------------------- | ---------------------------------- |
| `db_aclimate_data` | db_aclimate | /var/lib/postgresql/data    | Entire climate database            |
| `db_keycloak_data` | db_keycloak | /var/lib/postgresql/data    | Keycloak DB (users, clients)       |
| `keycloak_data`    | keycloak    | /opt/keycloak/data          | Cache, offline sessions            |
| `geoserver_data`   | geoserver   | /opt/geoserver/data_dir     | Workspaces, stores, layers, styles |
| `geoserver_gwc`    | geoserver   | /opt/geoserver/data_dir/gwc | Tile cache (GeoWebCache)           |

### Mounted configuration (tracked in git)

| Path                                  | Service     | Contents                                                                       |
| ------------------------------------- | ----------- | ------------------------------------------------------------------------------ |
| `config/keycloak/aclimate-realm.json` | keycloak    | Pre-configured realm (clients: `aclimate_frontend_honduras`, `aclimate_admin`) |
| `config/keycloak/themes/`             | keycloak    | Custom login pages                                                             |
| `config/keycloak/providers/`          | keycloak    | SPI extensions (JARs)                                                          |
| `config/geoserver/fonts/`             | geoserver   | Map fonts                                                                      |
| `bootstrap/db/init/`                  | db_aclimate | First-boot SQL/sh scripts (includes dump restore)                              |

---

## 🗺️ GeoServer — Bootstrap data

GeoServer starts with a pre-configured data directory copied on **first start** (empty volume) from `bootstrap/geoserver/data_dir/`. The copy is performed by `bootstrap/geoserver/init.sh`, which is idempotent: it only copies when the volume is empty.

### 📁 Supported structure (important!)

The `data_dir` **must follow this exact layout** for GeoServer to load workspaces, stores, and layers correctly:

```
bootstrap/geoserver/data_dir/
├── .gitkeep                      ← keeps the folder in git (only this file is tracked)
├── workspace.xml                 ← ID of the default workspace (see below)
├── data/                         ← actual raster/vector data files (TIFs, shapefiles, .properties)
└── workspaces/
    └── <workspace_name>/         ← e.g. climate_index
        ├── workspace.xml         ← workspace definition (must have <isolated>false</isolated>)
        ├── namespace.xml         ← namespace definition (must have <isolated>false</isolated>)
        ├── wms.xml               ← WMS service config for this workspace
        ├── wfs.xml               ← WFS service config for this workspace
        ├── wcs.xml               ← WCS service config for this workspace
        ├── styles/               ← SLD styles + their XML definitions
        │   ├── <style_name>.sld
        │   └── <style_name>.xml
        └── <store_name>/         ← one folder per coverage store
            ├── coveragestore.xml ← store definition (references data path)
            └── <store_name>/     ← folder with same name as store
                ├── coverage.xml  ← raster/vector coverage definition
                └── layer.xml     ← layer definition (references style)
```

### ⚠️ Critical rules for a working bootstrap

| Rule                                                                                   | Why                                                                          |
| -------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| `workspace.xml` and `namespace.xml` **must be inside** `workspaces/<name>/`            | Without them GeoServer does NOT load the workspace                           |
| `<isolated>` must be `false` in both                                                   | `true` hides the workspace and breaks GetCapabilities (NullPointerException) |
| `wms.xml`, `wfs.xml`, `wcs.xml` must be **inside the workspace folder**                | Root-level service files cause "No default workspace was found"              |
| `styles/` must be **inside the workspace folder**                                      | GeoServer looks for SLD resources relative to the workspace                  |
| `workspace.xml` at data_dir **root** must contain ONLY the ID of the default workspace | This file declares which workspace is the default                            |

Example of `workspace.xml` at data_dir root (default workspace pointer):

```xml
<workspace>
  <id>WorkspaceInfoImpl--3810f31d:19a3d0b823e:2426</id>
</workspace>
```

Example of `workspaces/climate_index/workspace.xml`:

```xml
<workspace>
  <id>WorkspaceInfoImpl--3810f31d:19a3d0b823e:2426</id>
  <name>climate_index</name>
  <isolated>false</isolated>
  <dateCreated>2025-11-10 16:26:31.205 UTC</dateCreated>
  <dateModified>2025-11-10 16:26:46.813 UTC</dateModified>
</workspace>
```

Example of `coveragestore.xml` (note the `url` points to `data/`):

```xml
<coverageStore>
  <id>CoverageStoreInfoImpl--3810f31d:19d37980855:-44de</id>
  <name>climate_index_annual_sv_CDD</name>
  <type>ImageMosaic</type>
  <enabled>true</enabled>
  <workspace>
    <id>WorkspaceInfoImpl--3810f31d:19a3d0b823e:2426</id>
  </workspace>
  <url>file:data/climate_index/climate_index_annual_sv_CDD</url>
</coverageStore>
```

### How to seed your own data

```bash
# 1. Export the data_dir from an existing GeoServer
scp -r user@server:/opt/geoserver/data_dir/* bootstrap/geoserver/data_dir/

# 2. If you already started the stack before, wipe the volume:
docker compose down -v

# 3. Start (bootstrap copies data_dir automatically)
docker compose --profile db up -d
```

> ⚠️ `bootstrap/geoserver/data_dir/` is **gitignored** (heavy raster data). Only `.gitkeep` and `init.sh` are tracked. No manual editing needed — just drop your exported data_dir there.

---

## 🛠️ Troubleshooting

| Problem                          | Solution                                                                                                 |
| -------------------------------- | -------------------------------------------------------------------------------------------------------- |
| WebAPI does not start            | Wait: the API takes ~45s to import rasterio/geopandas. `docker compose ps` must show `healthy`           |
| Keycloak `unhealthy`             | The healthcheck uses management port 9000. Check: `curl localhost:9000/health/ready`                     |
| GeoServer `restarting`           | Check logs: `docker logs aclimate_geoserver`. Often a charset issue in passwords — escape them in `.env` |
| Frontend 404 on `/ahuachapansur` | The container always serves on `/`. The basePath is handled by the reverse proxy (Phase 2)               |
| Reset EVERYTHING                 | `docker compose --profile db down -v` (deletes data and volumes)                                         |

---

## 🔐 Keycloak — Realm setup

The Keycloak realm is imported on first start. There are **two files**:

| File                                          | Committed | Contents                                             |
| --------------------------------------------- | --------- | ---------------------------------------------------- |
| `config/keycloak/aclimate-realm.example.json` | ✅ Yes    | Template with placeholders (`CHANGE_ME_*`)           |
| `config/keycloak/aclimate-realm.json`         | ❌ No     | Real secrets (gitignored) — create from the template |

### 1. Create your realm file

```bash
cp config/keycloak/aclimate-realm.example.json config/keycloak/aclimate-realm.json
```

Then edit the `CHANGE_ME_*` values:

| Placeholder                | Replace with                                       |
| -------------------------- | -------------------------------------------------- |
| `CHANGE_ME_DEV_SECRET`     | WebAPI/frontend client secret                      |
| `CHANGE_ME_ADMIN_SECRET`   | Admin panel client secret                          |
| `CHANGE_ME_ADMIN_PASSWORD` | Initial admin user password (default dev: `admin`) |

> ⚠️ `aclimate-realm.json` is gitignored — never commit real secrets. Only the `.example` file is tracked.

### 2. What gets created on first start

| Client                       | Type         | Use                             |
| ---------------------------- | ------------ | ------------------------------- |
| `aclimate_frontend_honduras` | confidential | API + Frontend (login/password) |
| `aclimate_admin`             | confidential | Admin panel                     |

Initial user: `admin` (password from `CHANGE_ME_ADMIN_PASSWORD`)

### 3. Admin permissions bootstrap (automatic)

The DB init scripts **auto-grant full permissions** to the Keycloak admin on first clean start:

```
bootstrap/db/init/04-ensure-admin-user.sh   ← inserts admin into `users` table
bootstrap/db/init/05-admin-permissions.sql  ← grants create/read/update/delete on all modules & countries
```

The admin's **UUID is read dynamically** from `aclimate-realm.json` by `04-ensure-admin-user.sh` — so if you change the admin `id` in the realm file, the script adapts automatically (single source of truth, no need to edit the script).

> Users created later from the admin panel do **not** get automatic permissions — assign them via the panel's user management module.

---

## 🚀 Deployment / Production

### Ports behind a reverse proxy

| Service   | Suggested public URL                  |
| --------- | ------------------------------------- |
| Frontend  | `https://aclimate.org/ahuachapansur/` |
| WebAPI    | `https://aclimate.org/api/`           |
| Keycloak  | `https://auth.aclimate.org/`          |
| GeoServer | `https://geo.aclimate.org/geoserver/` |

### Production steps

1. **Change ports** in `.env` if needed
2. **Set `HEALTH_TOKEN`** to protect health endpoints
3. **Keycloak**: switch from `start-dev` to `start` with HTTPS (`KC_HTTPS_*`)
4. **DBs**: use managed instances (RDS/Cloud SQL) without the `db` profile
5. **Reverse proxy** (Nginx/Traefik) routing each service
