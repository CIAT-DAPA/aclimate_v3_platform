# 🌦️ AClimate v3 Platform

Docker Compose orchestration for the AClimate v3 ecosystem. Launches the API, Frontend, Keycloak, GeoServer, and databases with **a single command** — with persistence and auto-generated URLs.

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
         └───────────┬───────────┘
                     ▼
            ┌──────────────────┐
            │    frontend      │
            │   Build local    │
            │   port: 3000     │
            └──────────────────┘
```

**8 services** from the repos:

- **API**: `ghcr.io/ciat-dapa/aclimate_v3_webapi` ([repo](https://github.com/CIAT-DAPA/aclimate_v3_webapi))
- **Frontend**: local build from `aclimate_v3_frontend` ([repo](https://github.com/CIAT-DAPA/aclimate_v3_frontend))
- **Admin**: local build from `aclimate_v3_admin` ([repo](https://github.com/CIAT-DAPA/aclimate_v3_admin))
- **Users API**: `ghcr.io/ciat-dapa/aclimate_v3_frontend_users_webapi` ([repo](https://github.com/CIAT-DAPA/aclimate_v3_frontend_users_webapi)) — user preferences/stations backend
- **Keycloak** + **GeoServer** + **2x PostgreSQL (PostGIS)**

---

## 📌 Prerequisites

- Docker Engine 24+ with Compose plugin
- `aclimate_v3_frontend` cloned next to this repo (or set `FRONTEND_PATH`)
- Access to `ghcr.io` for the API image

```bash
# Recommended layout
d:\Code\
├── aclimate_v3_platform/    ← this repo
├── aclimate_v3_frontend/    ← required clone
└── aclimate_v3_webapi/      ← (only if you want to work on the source)
```

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
| `FRONTEND_PATH`                         | `../aclimate_v3_frontend`    | Path to the frontend repo                  |

---

## 🗄️ Database — Bootstrap and dumps

The `aclimate` database is restored automatically on the **first start** (empty volume) from a dump:

```
bootstrap/db/dumps/       ← put your .dump / .backup / .sql.gz here
```

**Dumps are NOT committed to git** (see `.gitignore`). To restore from your local dump:

```bash
# 1. Copy your dump
copy C:\Users\YOUR_USER\Downloads\aclimate_pg_20260528.dump bootstrap\db\dumps\

# 2. If you already started the stack before, wipe the data volume:
docker compose down -v

# 3. Start again (automatic restore)
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

## 📈 Monitoring (Grafana + Prometheus + Loki + Blackbox)

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

### What is monitored

| Data                                                      | Source                                  |
| --------------------------------------------------------- | --------------------------------------- |
| Uptime + latency of WebAPI, Frontend, Keycloak, GeoServer | Blackbox → Prometheus (`probe_success`) |
| Keycloak JVM, HTTP requests, threads, errors              | Keycloak `/metrics` → Prometheus        |
| Logs of **all** containers                                | Promtail → Loki                         |

### Dashboard: `AClimate Overview` (auto-provisioned)

| Panel                           | Type       | Source     |
| ------------------------------- | ---------- | ---------- |
| Service Status (blackbox)       | table      | Prometheus |
| Response Time (blackbox)        | timeseries | Prometheus |
| Container Logs                  | logs       | Loki       |
| Log Volume per Container        | timeseries | Loki       |
| Keycloak Request Rate           | timeseries | Prometheus |
| Keycloak JVM Heap Memory        | timeseries | Prometheus |
| Total HTTP 200 / 5xx (Keycloak) | stat       | Prometheus |
| JVM Live Threads                | stat       | Prometheus |

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

## 🛠️ Troubleshooting

| Problem                          | Solution                                                                                                 |
| -------------------------------- | -------------------------------------------------------------------------------------------------------- |
| WebAPI does not start            | Wait: the API takes ~45s to import rasterio/geopandas. `docker compose ps` must show `healthy`           |
| Keycloak `unhealthy`             | The healthcheck uses management port 9000. Check: `curl localhost:9000/health/ready`                     |
| GeoServer `restarting`           | Check logs: `docker logs aclimate_geoserver`. Often a charset issue in passwords — escape them in `.env` |
| Frontend 404 on `/ahuachapansur` | The container always serves on `/`. The basePath is handled by the reverse proxy (Phase 2)               |
| Reset EVERYTHING                 | `docker compose --profile db down -v` (deletes data and volumes)                                         |

---

## 🔐 Keycloak — Bootstrap realm

On first start, `config/keycloak/aclimate-realm.json` is imported, creating:

| Client                       | Type         | Use                                |
| ---------------------------- | ------------ | ---------------------------------- |
| `aclimate_frontend_honduras` | confidential | API + Frontend (login/password)    |
| `aclimate_admin`             | confidential | Admin panel (reserved for Phase 2) |

Initial user: `admin` / `admin`

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
