# Chatwoot en Kubernetes – Variables de entorno y despliegue

Guía de referencia para levantar Chatwoot en producción sobre Kubernetes: lista de variables de entorno y componentes necesarios.

---

## 1. Variables de entorno para producción

En Kubernetes conviene separar:

- **ConfigMap**: variables no sensibles (URLs, timeouts, flags).
- **Secret**: contraseñas, tokens, claves de encriptación, `SECRET_KEY_BASE`.

Todas las variables que usa la aplicación en producción (Rails + Sidekiq) están listadas abajo. Las que debes poner en **Secret** están marcadas con `[SECRET]`.

### 1.1 Core (obligatorias)

| Variable | Ejemplo / Notas | Dónde |
|----------|------------------|--------|
| `RAILS_ENV` | `production` | ConfigMap |
| `SECRET_KEY_BASE` | Generar: `bundle exec rake secret` (128+ caracteres alfanuméricos) | **Secret** |
| `FRONTEND_URL` | `https://chat.tu-dominio.com` | ConfigMap |
| `INSTALLATION_ENV` | `kubernetes` o `docker` | ConfigMap |

### 1.2 Base de datos (PostgreSQL)

| Variable | Ejemplo / Notas | Dónde |
|----------|------------------|--------|
| `POSTGRES_HOST` | Servicio K8s (`postgres`) o **GCP Cloud SQL**: IP privada de la instancia, o `127.0.0.1` si usas Cloud SQL Auth Proxy | ConfigMap |
| `POSTGRES_PORT` | `5432` | ConfigMap |
| `POSTGRES_DATABASE` | `chatwoot_production` (default en prod) | ConfigMap |
| `POSTGRES_USERNAME` | Usuario de la BD (en GCP: usuario de la instancia Cloud SQL) | ConfigMap o Secret |
| `POSTGRES_PASSWORD` | Contraseña de la BD | **Secret** |
| `POSTGRES_STATEMENT_TIMEOUT` | `14s` | ConfigMap |
| `RAILS_MAX_THREADS` | `5` | ConfigMap |

Requisito: PostgreSQL 16 con extensión **pgvector**. Si usas **Cloud SQL en GCP**, crea la instancia con pgvector, configura la conexión (IP privada o Cloud SQL Proxy) y usa sus credenciales en Secret/ConfigMap.

### 1.3 Redis

| Variable | Ejemplo / Notas | Dónde |
|----------|------------------|--------|
| `REDIS_URL` | `redis://:PASSWORD@redis:6379` (reemplaza PASSWORD) | **Secret** (si incluye password) |
| `REDIS_PASSWORD` | Contraseña de Redis | **Secret** |

Opcional (Redis Sentinel):

- `REDIS_SENTINELS`
- `REDIS_SENTINEL_MASTER_NAME`
- `REDIS_SENTINEL_PASSWORD`

### 1.4 Email / SMTP

| Variable | Ejemplo / Notas | Dónde |
|----------|------------------|--------|
| `MAILER_SENDER_EMAIL` | `Albatros <noreply@tu-dominio.com>` | ConfigMap |
| `SMTP_ADDRESS` | `smtp.gmail.com` | ConfigMap |
| `SMTP_PORT` | `587` | ConfigMap |
| `SMTP_USERNAME` | Correo o usuario SMTP | ConfigMap o Secret |
| `SMTP_PASSWORD` | Contraseña o App Password | **Secret** |
| `SMTP_AUTHENTICATION` | `plain` o `login` | ConfigMap |
| `SMTP_DOMAIN` | `gmail.com` o tu dominio | ConfigMap |
| `SMTP_ENABLE_STARTTLS_AUTO` | `true` | ConfigMap |
| `SMTP_OPENSSL_VERIFY_MODE` | `peer` | ConfigMap |
| `MAILER_INBOUND_EMAIL_DOMAIN` | `reply.tu-dominio.com` (si usas reply por email) | ConfigMap |

Opcional: `RAILS_INBOUND_EMAIL_SERVICE`, `RAILS_INBOUND_EMAIL_PASSWORD`, etc. (solo si configuras Action Mailbox).

### 1.5 Encriptación (2FA / MFA)

Generar con: `bundle exec rails db:encryption:init`

| Variable | Dónde |
|----------|--------|
| `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY` | **Secret** |
| `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY` | **Secret** |
| `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT` | **Secret** |

### 1.6 Almacenamiento

**Local (por defecto):**

| Variable | Valor |
|----------|--------|
| `ACTIVE_STORAGE_SERVICE` | `local` |

En K8s necesitas un PVC montado donde Rails escribe (ej: `/app/storage`).

**Amazon S3:**

| Variable | Dónde |
|----------|--------|
| `ACTIVE_STORAGE_SERVICE` | `amazon` – ConfigMap |
| `AWS_ACCESS_KEY_ID` | **Secret** |
| `AWS_SECRET_ACCESS_KEY` | **Secret** |
| `AWS_REGION` | ConfigMap |
| `S3_BUCKET_NAME` | ConfigMap |

**S3-compatible (Spaces, MinIO):**

| Variable | Dónde |
|----------|--------|
| `ACTIVE_STORAGE_SERVICE` | `s3_compatible` – ConfigMap |
| `STORAGE_ACCESS_KEY_ID` | **Secret** |
| `STORAGE_SECRET_ACCESS_KEY` | **Secret** |
| `STORAGE_REGION` | ConfigMap |
| `STORAGE_BUCKET_NAME` | ConfigMap |
| `STORAGE_ENDPOINT` | ConfigMap |

### 1.7 Logging y SSL

| Variable | Valor típico | Dónde |
|----------|----------------|--------|
| `RAILS_LOG_TO_STDOUT` | `true` | ConfigMap |
| `LOG_LEVEL` | `info` | ConfigMap |
| `LOG_SIZE` | `500` | ConfigMap |
| `LOGRAGE_ENABLED` | `true` (opcional) | ConfigMap |
| `FORCE_SSL` | `true` en producción | ConfigMap |
| `ASSET_CDN_HOST` | Opcional, ej: `https://cdn.tu-dominio.com` | ConfigMap |

### 1.8 Sidekiq

| Variable | Valor típico | Dónde |
|----------|----------------|--------|
| `SIDEKIQ_CONCURRENCY` | `10` | ConfigMap |

### 1.9 Opcionales (signup, integraciones, APM)

| Variable | Uso | Dónde |
|----------|-----|--------|
| `ENABLE_ACCOUNT_SIGNUP` | `true` / `false` / `api_only` | ConfigMap |
| `DEFAULT_LOCALE` | Idioma por defecto | ConfigMap |
| `HELPCENTER_URL` | URL del help center | ConfigMap |
| `FB_APP_ID`, `FB_APP_SECRET`, `FB_VERIFY_TOKEN` | Facebook | Secret/ConfigMap |
| `GOOGLE_OAUTH_CLIENT_ID`, `GOOGLE_OAUTH_CLIENT_SECRET`, `GOOGLE_OAUTH_CALLBACK_URL` | Google OAuth | Secret/ConfigMap |
| `SLACK_CLIENT_ID`, `SLACK_CLIENT_SECRET` | Slack | Secret/ConfigMap |
| `SENTRY_DSN` | Sentry | ConfigMap o Secret |
| `NEW_RELIC_LICENSE_KEY` | New Relic | Secret |
| `DD_TRACE_AGENT_URL` | Datadog | ConfigMap |
| `ENABLE_RACK_ATTACK` | `true` para rate limiting | ConfigMap |
| `MAXIMUM_FILE_UPLOAD_SIZE` | Tamaño max subida (ej: 40) | ConfigMap |

---

## 2. Lista plana para ConfigMap/Secret (referencia)

Puedes usar esta lista para armar un único bloque de env (o un `.env` de referencia) y luego repartir en ConfigMap y Secret.

```env
# === OBLIGATORIAS ===
RAILS_ENV=production
SECRET_KEY_BASE=<generar con: bundle exec rake secret>
FRONTEND_URL=https://chat.tu-dominio.com
INSTALLATION_ENV=kubernetes

POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_DATABASE=chatwoot_production
POSTGRES_USERNAME=chatwoot_prod
POSTGRES_PASSWORD=<SECRET>
POSTGRES_STATEMENT_TIMEOUT=14s
RAILS_MAX_THREADS=5

REDIS_URL=redis://:REDIS_PASSWORD@redis:6379
REDIS_PASSWORD=<SECRET>

MAILER_SENDER_EMAIL=Albatros <noreply@tu-dominio.com>
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=tu-correo@gmail.com
SMTP_PASSWORD=<SECRET>
SMTP_AUTHENTICATION=plain
SMTP_DOMAIN=gmail.com
SMTP_ENABLE_STARTTLS_AUTO=true
SMTP_OPENSSL_VERIFY_MODE=peer
MAILER_INBOUND_EMAIL_DOMAIN=reply.tu-dominio.com

ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=<SECRET>
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=<SECRET>
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=<SECRET>

ACTIVE_STORAGE_SERVICE=local
RAILS_LOG_TO_STDOUT=true
LOG_LEVEL=info
LOG_SIZE=500
FORCE_SSL=true
SIDEKIQ_CONCURRENCY=10
ENABLE_ACCOUNT_SIGNUP=false
```

Generar claves de encriptación (una sola vez):

```bash
bundle exec rails db:encryption:init
```

---

## 3. Qué necesitas para ejecutar en Kubernetes

### 3.1 Arquitectura mínima

```
                    +-----------+
                    |  Ingress  |
                    | (HTTPS)   |
                    +-----+-----+
                          |
                  +-------+-------+
                  |               |
           +------+------+ +-----+------+
           | Rails (web) | | Sidekiq    |
           | port 3000   | | (worker)   |
           | replicas: 2 | | replicas: 1|
           +------+------+ +-----+------+
                  |               |
          +-------+-------+-------+
          |               |
   +------+------+ +-----+------+
   | PostgreSQL  | |   Redis    |
   | pgvector:16 | |   alpine   |
   +-------------+ +------------+
```

### 3.2 Componentes a desplegar (orden sugerido)

| Orden | Componente | Tipo | Descripción |
|-------|------------|------|-------------|
| 1 | Namespace | Namespace | ej: `chatwoot` |
| 2 | ConfigMap | ConfigMap | Env no sensibles (ver sección 1) |
| 3 | Secret | Secret | Contraseñas, SECRET_KEY_BASE, claves encriptación, SMTP_PASSWORD, REDIS_PASSWORD, POSTGRES_PASSWORD |
| 4 | PostgreSQL | StatefulSet + Service | PostgreSQL 16 con extensión pgvector, PVC ej: 10Gi |
| 5 | Redis | StatefulSet + Service | Redis (Alpine), PVC ej: 2Gi |
| 6 | Migration Job | Job | Una vez: `bundle exec rails db:chatwoot_prepare` (o release step si usas Helm) |
| 7 | Rails (web) | Deployment | Imagen Chatwoot, 2+ replicas, puerto 3000, env desde ConfigMap + Secret |
| 8 | Sidekiq | Deployment | Misma imagen, comando Sidekiq, 1+ replica, mismo env |
| 9 | Service (web) | Service | ClusterIP, puerto 80 → 3000 |
| 10 | Ingress | Ingress | TLS (cert-manager o similar), host → Service web |

### 3.3 Recursos sugeridos por pod

| Pod | Request (mem/cpu) | Limit (mem/cpu) |
|-----|-------------------|------------------|
| Rails (web) | 512Mi / 250m | 1Gi / 1 |
| Sidekiq | 512Mi / 250m | 1.2Gi / 1 |
| PostgreSQL | 512Mi / 250m | 1Gi / 500m |
| Redis | 128Mi / 100m | 256Mi / 250m |

### 3.4 Health checks (Rails)

Usar el endpoint `/health` (responde `{ "status": "woot" }`, HTTP 200, sin auth):

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 30
  periodSeconds: 15

readinessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 20
  periodSeconds: 10
```

### 3.5 Comandos de los contenedores

- **Rails (web):** el que trae la imagen (ej: `bundle exec rails server` o el definido en Procfile para `web`). Debe ejecutar también `ip_lookup:setup` si la imagen lo usa (ver `Procfile`).
- **Sidekiq:** `bundle exec sidekiq -C config/sidekiq.yml`.
- **Migration (Job):** `bundle exec rails db:chatwoot_prepare` (o el release step equivalente).

### 3.6 Hosts y puertos en K8s

- **PostgreSQL:** nombre del servicio (ej: `postgres` o `chatwoot-postgres`) en el mismo namespace; puerto `5432`. Configurar `POSTGRES_HOST` y `POSTGRES_PORT` acorde.
- **Redis:** nombre del servicio (ej: `redis`); puerto `6379`. `REDIS_URL` debe usar ese nombre como host.

### 3.7 Almacenamiento local en K8s

Si usas `ACTIVE_STORAGE_SERVICE=local`, el directorio donde Rails escribe (ej: `/app/storage`) debe ser un **PersistentVolumeClaim** montado en el Deployment de Rails (y opcionalmente en Sidekiq si los jobs tocan archivos). Mismo PVC o uno compartido según tu diseño.

### 3.8 Escalado

```bash
# Más réplicas web
kubectl scale deployment chatwoot-web --replicas=4 -n chatwoot

# Más workers Sidekiq
kubectl scale deployment chatwoot-worker --replicas=2 -n chatwoot
```

Opcional: HPA (Horizontal Pod Autoscaler) por CPU/memoria.

---

## 4. Checklist rápido

- [ ] PostgreSQL 16 con pgvector desplegado y accesible desde el namespace.
- [ ] Redis desplegado y accesible.
- [ ] `SECRET_KEY_BASE` generado y en Secret.
- [ ] Claves de encriptación generadas (`rails db:encryption:init`) y en Secret.
- [ ] ConfigMap y Secret con todas las variables de la sección 1 (ajustadas a tu dominio, SMTP, storage).
- [ ] Job de migración ejecutado y terminado correctamente.
- [ ] Deployment Rails con probes en `/health`.
- [ ] Deployment Sidekiq con el mismo env que Rails.
- [ ] Service y Ingress con TLS y `FRONTEND_URL` coherente con el host público.
- [ ] Si storage local: PVC montado en el path que usa la app.

Más detalle de arquitectura y checklist general en [PRODUCTION.md](./PRODUCTION.md#kubernetes).
