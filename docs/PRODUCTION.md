# Chatwoot & ave_chatwoot_api - Guia de Produccion

## Tabla de contenidos

- [Chatwoot](#chatwoot)
  - [Requisitos del sistema](#requisitos-del-sistema)
  - [Docker Compose](#docker-compose)
  - [Variables de entorno](#variables-de-entorno)
  - [Branding Albatros](#branding-albatros)
  - [Procesos en produccion](#procesos-en-produccion)
  - [Comandos de despliegue](#comandos-de-despliegue)
  - [Sidekiq (background jobs)](#sidekiq-background-jobs)
  - [Almacenamiento de archivos](#almacenamiento-de-archivos)
  - [Base de datos](#base-de-datos)
  - [Seguridad](#seguridad)
  - [Monitoreo y health checks](#monitoreo-y-health-checks)
  - [Escalado](#escalado)
  - [Custom Attributes](#custom-attributes)
- [ave_chatwoot_api](#ave_chatwoot_api)
  - [Que es](#que-es)
  - [Requisitos](#requisitos)
  - [Configuracion](#configuracion)
  - [Autenticacion](#autenticacion)
  - [Endpoints principales](#endpoints-principales)
  - [Docker](#docker)
  - [CI/CD](#cicd)
- [Kubernetes](#kubernetes)
  - [Arquitectura](#arquitectura)
  - [Componentes necesarios](#componentes-necesarios)
  - [Orden de despliegue](#orden-de-despliegue)
  - [Health checks](#health-checks)
  - [Escalado horizontal](#escalado-horizontal)
- [Checklist de despliegue](#checklist-de-despliegue)

---

## Chatwoot

### Requisitos del sistema

| Componente | Version  |
| ---------- | -------- |
| Ruby       | 3.4.4    |
| Node.js    | 24.13.0  |
| pnpm       | 10.x     |
| PostgreSQL | 16 (con extension `pgvector`) |
| Redis      | Alpine   |
| Bundler    | 2.5.16   |

### Docker Compose

El proyecto incluye `docker-compose.production.yaml` con 4 servicios:

| Servicio   | Imagen                      | Puerto | Descripcion                        |
| ---------- | --------------------------- | ------ | ---------------------------------- |
| rails      | chatwoot/chatwoot:latest    | 3000   | Servidor web                       |
| sidekiq    | chatwoot/chatwoot:latest    | -      | Procesador de jobs en background   |
| postgres   | pgvector/pgvector:pg16      | 5432   | Base de datos                      |
| redis      | redis:alpine                | 6379   | Cache y colas                      |

Volumenes persistentes: `postgres_data`, `redis_data`, `storage_data`.

### Variables de entorno

#### Core (requeridas)

```env
RAILS_ENV=production
SECRET_KEY_BASE=<generar con: rake secret>
FRONTEND_URL=https://tu-dominio.com
INSTALLATION_ENV=docker
```

#### Base de datos

```env
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_DATABASE=chatwoot_production
POSTGRES_USERNAME=chatwoot_prod
POSTGRES_PASSWORD=<contrasena-segura>
POSTGRES_STATEMENT_TIMEOUT=14s
RAILS_MAX_THREADS=5
```

#### Redis

```env
REDIS_URL=redis://:password@redis:6379
REDIS_PASSWORD=<contrasena-redis>
```

Soporta Redis Sentinel para alta disponibilidad:

```env
REDIS_SENTINELS=sentinel1:26379,sentinel2:26379
REDIS_SENTINEL_MASTER_NAME=mymaster
```

#### Email/SMTP

```env
MAILER_SENDER_EMAIL=Albatros <noreply@tu-dominio.com>
SMTP_ADDRESS=smtp.tu-proveedor.com
SMTP_PORT=587
SMTP_USERNAME=<usuario>
SMTP_PASSWORD=<contrasena>
SMTP_AUTHENTICATION=plain
SMTP_ENABLE_STARTTLS_AUTO=true
SMTP_OPENSSL_VERIFY_MODE=peer
MAILER_INBOUND_EMAIL_DOMAIN=reply.tu-dominio.com
```

#### Encriptacion (requerido para 2FA)

```env
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=<generar>
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=<generar>
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=<generar>
```

Generar con:

```bash
rails db:encryption:init
```

#### Almacenamiento

**Local (por defecto):**

```env
ACTIVE_STORAGE_SERVICE=local
```

**Amazon S3:**

```env
ACTIVE_STORAGE_SERVICE=amazon
AWS_ACCESS_KEY_ID=<key>
AWS_SECRET_ACCESS_KEY=<secret>
AWS_REGION=us-east-1
S3_BUCKET_NAME=chatwoot-storage
```

**Google Cloud Storage:**

```env
ACTIVE_STORAGE_SERVICE=google
GCS_PROJECT=<proyecto>
GCS_CREDENTIALS=<json>
GCS_BUCKET=<bucket>
```

**S3-compatible (DigitalOcean Spaces, MinIO):**

```env
ACTIVE_STORAGE_SERVICE=s3_compatible
STORAGE_ACCESS_KEY_ID=<key>
STORAGE_SECRET_ACCESS_KEY=<secret>
STORAGE_REGION=<region>
STORAGE_BUCKET_NAME=<bucket>
STORAGE_ENDPOINT=<url>
```

#### Logging

```env
RAILS_LOG_TO_STDOUT=true
LOG_LEVEL=info
LOG_SIZE=500
LOGRAGE_ENABLED=true
```

#### SSL

```env
FORCE_SSL=true
ASSET_CDN_HOST=https://cdn.tu-dominio.com
```

#### Sidekiq

```env
SIDEKIQ_CONCURRENCY=10
```

#### Integraciones opcionales

```env
# Facebook
FB_APP_ID=
FB_APP_SECRET=
FB_VERIFY_TOKEN=

# Google OAuth
GOOGLE_OAUTH_CLIENT_ID=
GOOGLE_OAUTH_CLIENT_SECRET=

# Slack
SLACK_CLIENT_ID=
SLACK_CLIENT_SECRET=

# APM/Monitoring
SENTRY_DSN=
NEW_RELIC_LICENSE_KEY=
```

### Branding Albatros

Configurado en `config/installation_config.yml`:

```yaml
INSTALLATION_NAME: 'Albatros'
LOGO: '/brand-assets/logo.jpg'
LOGO_DARK: '/brand-assets/logo_dark.jpg'
LOGO_THUMBNAIL: '/brand-assets/logo_thumbnail.jpg'
BRAND_NAME: 'Albatros'
BRAND_URL: 'https://www.albatros.com'
```

Los assets estan en `public/brand-assets/`.

### Procesos en produccion

Definidos en `Procfile`:

```
release: POSTGRES_STATEMENT_TIMEOUT=600s bundle exec rails db:chatwoot_prepare
web:     bundle exec rails ip_lookup:setup && bin/rails server -p $PORT
worker:  bundle exec rails ip_lookup:setup && bundle exec sidekiq -C config/sidekiq.yml
```

- **release**: Ejecuta migraciones de base de datos
- **web**: Servidor Rails (Puma)
- **worker**: Sidekiq para jobs en background

### Comandos de despliegue

```bash
# Preparar base de datos (migraciones + setup)
bundle exec rails db:chatwoot_prepare

# Precompilar assets
bundle exec rake assets:precompile

# Iniciar con Docker Compose
docker compose -f docker-compose.production.yaml up -d
```

### Sidekiq (background jobs)

Configuracion en `config/sidekiq.yml`. Colas ordenadas por prioridad:

1. `critical`
2. `high`
3. `medium`
4. `default`
5. `mailers`
6. `action_mailbox_routing`
7. `low`
8. `scheduled_jobs`
9. `deferred`
10. `purgable`
11. `housekeeping`

Timeout: 25s | Max retries: 3 | Concurrencia: 10 (configurable via `SIDEKIQ_CONCURRENCY`).

### Almacenamiento de archivos

| Servicio       | Variable                   |
| -------------- | -------------------------- |
| Local          | `ACTIVE_STORAGE_SERVICE=local` (archivos en `/app/storage`) |
| Amazon S3      | `ACTIVE_STORAGE_SERVICE=amazon` |
| Google Cloud   | `ACTIVE_STORAGE_SERVICE=google` |
| Azure Blob     | `ACTIVE_STORAGE_SERVICE=microsoft` |
| S3-compatible  | `ACTIVE_STORAGE_SERVICE=s3_compatible` |

Limite de subida: configurable con `MAXIMUM_FILE_UPLOAD_SIZE` (default: 40MB).

### Base de datos

- PostgreSQL 16 con extension **pgvector** (para embeddings/vector search)
- Connection pooling dinamico segun proceso (Sidekiq usa `SIDEKIQ_CONCURRENCY`, web usa `RAILS_MAX_THREADS`)
- Reaping frequency: 30s (configurable con `DB_POOL_REAPING_FREQUENCY`)
- Credenciales por defecto en desarrollo:

```
Host:     localhost
Puerto:   5432
Database: chatwoot_dev
Usuario:  postgres
Password: postgres (definido en .env)
```

Acceso via terminal:

```bash
psql -h localhost -U postgres chatwoot_dev
# o
bundle exec rails dbconsole
```

### Seguridad

- `SECRET_KEY_BASE` requerido (generar con `rake secret`, 128+ chars alfanumericos)
- Claves de encriptacion requeridas para 2FA
- Rate limiting disponible con Rack::Attack (`ENABLE_RACK_ATTACK=true`)
- CORS configurado via Rack::CORS
- HTTPS forzado con `FORCE_SSL=true`
- Login por defecto con Devise (ruta: `/auth/sign_in`)

Credenciales de seed en desarrollo:

```
Email:    john@acme.inc
Password: Password1!
```

### Monitoreo y health checks

**Health endpoint:**

```
GET /health -> { status: "woot" } (HTTP 200)
```

No requiere autenticacion. Usar para liveness/readiness probes.

**Sidekiq health:** Gem `sidekiq_alive` proporciona monitoreo del worker.

**APM soportados:**

| Servicio    | Variable              |
| ----------- | --------------------- |
| Sentry      | `SENTRY_DSN`          |
| Datadog     | `DD_TRACE_AGENT_URL`  |
| New Relic   | `NEW_RELIC_LICENSE_KEY` |
| Scout       | `SCOUT_KEY`           |
| Elastic APM | `ELASTIC_APM_SERVER_URL` |

### Escalado

**Horizontal (web):** Multiples instancias Rails detras de load balancer.

**Vertical:**

- `RAILS_MAX_THREADS`: hilos por proceso (default: 5)
- `WEB_CONCURRENCY`: workers Puma (default: 0)
- `SIDEKIQ_CONCURRENCY`: jobs concurrentes (default: 10)

### Custom Attributes

Chatwoot soporta campos personalizados para contactos y conversaciones.

**Tipos disponibles:** text, number, currency, percent, link, date, list, checkbox.

**Se aplican a:** Contactos (`contact_attribute`) y Conversaciones (`conversation_attribute`).

**Configuracion via UI:** Settings > Custom Attributes.

**Configuracion via API:**

```bash
# Crear definicion
POST /api/v1/accounts/{id}/custom_attribute_definitions
{
  "custom_attribute_definition": {
    "attribute_display_name": "ID Cliente",
    "attribute_key": "customer_id",
    "attribute_model": "contact_attribute",
    "attribute_display_type": "text"
  }
}

# Asignar valor a conversacion
POST /api/v1/accounts/{id}/conversations/{conv_id}/custom_attributes
{
  "custom_attributes": { "customer_id": "CLI-001" }
}

# Asignar valor a contacto
PATCH /api/v1/accounts/{id}/contacts/{contact_id}
{
  "custom_attributes": { "customer_id": "CLI-001" }
}
```

Validaciones: strings max 1500 chars, numeros max 9,999,999,999. Soporta regex.

---

## ave_chatwoot_api

### Que es

Wrapper/proxy de la API de Chatwoot. El bot (`bot_ave`) lo usa como intermediario para interactuar con Chatwoot (crear contactos, conversaciones, enviar mensajes, gestionar webhooks).

### Requisitos

| Componente | Version       |
| ---------- | ------------- |
| Node.js    | 16+ (Docker usa 20) |
| MongoDB    | Atlas o local |
| Puerto     | 19610         |

### Configuracion

Archivo `config/PROD.json`:

```json
{
  "PORT": 19610,
  "ENVIRONMENT_PROJECT": "PROD",
  "CHATWOOT_API_URL": "https://chat.tu-dominio.com",
  "CHATWOOT_TOKEN": "<token de acceso API de Chatwoot>",
  "CHATWOOT_ACCOUNT_ID": "<ID de cuenta>",
  "MONGO_URI": "mongodb+srv://<usuario>:<password>@<cluster>/<db>",
  "MONGO_DB_NAME": "api_keys",
  "MONGO_DB_COLLECTION": "apiKeys"
}
```

| Variable             | Descripcion                              |
| -------------------- | ---------------------------------------- |
| `PORT`               | Puerto del servicio                      |
| `CHATWOOT_API_URL`   | URL del Chatwoot de produccion           |
| `CHATWOOT_TOKEN`     | Token de acceso de la API de Chatwoot    |
| `CHATWOOT_ACCOUNT_ID`| ID de la cuenta en Chatwoot              |
| `MONGO_URI`          | URI de conexion a MongoDB                |
| `MONGO_DB_NAME`      | Nombre de la base de datos               |
| `MONGO_DB_COLLECTION`| Coleccion de API keys                    |

### Autenticacion

Usa API keys almacenadas en MongoDB. Cada request requiere el header `x-api-key`.

Insertar al menos una key en la coleccion `apiKeys`:

```json
{
  "appname": "AVE Chatwoot API",
  "name": "apiKey_Prod",
  "key": "<tu-api-key-generada>",
  "enabled": true,
  "_deleted": false
}
```

Las keys se cargan en memoria al iniciar el servicio.

### Endpoints principales

| Metodo | Ruta                                    | Descripcion               |
| ------ | --------------------------------------- | ------------------------- |
| GET    | `/ping`                                 | Health check              |
| GET    | `/api-docs`                             | Swagger UI                |
| POST   | `/api/chatwoot/inboxes`                 | Crear/buscar inbox        |
| POST   | `/api/chatwoot/inboxes/list`            | Listar inboxes            |
| POST   | `/api/chatwoot/contacts`                | Crear/buscar contacto     |
| POST   | `/api/chatwoot/contacts/list`           | Listar contactos          |
| POST   | `/api/chatwoot/conversations`           | Crear conversacion        |
| POST   | `/api/chatwoot/conversations/list/:phone` | Buscar por telefono     |
| POST   | `/api/chatwoot/messages`                | Enviar mensaje            |
| POST   | `/api/chatwoot/messages/directly`       | Enviar mensaje directo    |
| POST   | `/api/chatwoot/webhooks`                | Listar/crear webhooks     |
| PUT    | `/api/chatwoot/webhooks/:id`            | Actualizar webhook        |
| DELETE | `/api/chatwoot/webhooks/:id`            | Eliminar webhook          |

### Docker

```dockerfile
FROM node:20-alpine3.16
WORKDIR /usr/src/ave
COPY . /usr/src/ave
ENV NODE_ENV=DEV
RUN npm i && npm run build
EXPOSE 19610
CMD ["node", "build/server"]
```

Comandos:

```bash
# Build
npm install && npm run build

# Produccion local
node build/server

# Docker
docker build -t ave-chatwoot-api .
docker run -p 19610:19610 ave-chatwoot-api
```

### CI/CD

GitHub Actions despliega a Google Cloud Run al pushear a la rama `chat_provider_prd`.

| Parametro  | Valor                      |
| ---------- | -------------------------- |
| Plataforma | Google Cloud Run           |
| Proyecto   | `chatbot-samantha-1`       |
| Servicio   | `ave-chatprovider-api`     |
| Region     | `us-central1`              |
| Puerto     | 19610                      |
| Secret     | `GCP_SA_KEY` (service account JSON) |

---

## Kubernetes

### Arquitectura

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

### Componentes necesarios

| Componente   | Tipo        | Descripcion                         |
| ------------ | ----------- | ----------------------------------- |
| Namespace    | Namespace   | `chatwoot`                          |
| ConfigMap    | ConfigMap   | Variables de entorno no sensibles   |
| Secrets      | Secret      | Contrasenas, tokens, keys           |
| PostgreSQL   | StatefulSet | BD con PVC de 10Gi                  |
| Redis        | StatefulSet | Cache con PVC de 2Gi                |
| Migration    | Job         | `rails db:chatwoot_prepare`         |
| Rails (web)  | Deployment  | 2 replicas, puerto 3000             |
| Sidekiq      | Deployment  | 1 replica, concurrencia 10          |
| Web Service  | Service     | ClusterIP, puerto 80 -> 3000        |
| Ingress      | Ingress     | TLS con cert-manager                |

**Resources sugeridos:**

| Pod         | Request (mem/cpu) | Limit (mem/cpu) |
| ----------- | ----------------- | --------------- |
| Rails       | 512Mi / 250m      | 1Gi / 1         |
| Sidekiq     | 512Mi / 250m      | 1.2Gi / 1       |
| PostgreSQL  | 512Mi / 250m      | 1Gi / 500m      |
| Redis       | 128Mi / 100m      | 256Mi / 250m    |

### Orden de despliegue

1. Namespace
2. Secrets + ConfigMap
3. PostgreSQL + Redis (esperar que esten ready)
4. Migration Job (esperar que termine)
5. Rails Deployment + Sidekiq Deployment
6. Service + Ingress

### Health checks

```yaml
# Usar para liveness y readiness probes
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

Respuesta: `GET /health` -> `{ status: "woot" }` (HTTP 200, sin autenticacion).

### Escalado horizontal

```bash
# Web
kubectl scale deployment chatwoot-web --replicas=4 -n chatwoot

# Workers
kubectl scale deployment chatwoot-worker --replicas=2 -n chatwoot
```

Considerar HPA (Horizontal Pod Autoscaler) basado en CPU/memoria para autoescalado.

---

## Checklist de despliegue

### Chatwoot

- [ ] PostgreSQL 16 con pgvector disponible
- [ ] Redis disponible
- [ ] `SECRET_KEY_BASE` generado (`rake secret`)
- [ ] Claves de encriptacion generadas (`rails db:encryption:init`)
- [ ] SMTP configurado y probado
- [ ] Storage configurado (S3/local/GCS)
- [ ] `bundle exec rails db:chatwoot_prepare` ejecutado
- [ ] Assets precompilados
- [ ] Certificado SSL/TLS
- [ ] Reverse proxy (Nginx) o Ingress configurado
- [ ] `FRONTEND_URL` apuntando al dominio correcto
- [ ] Branding Albatros verificado en `config/installation_config.yml`
- [ ] Login funcional (`/auth/sign_in`)

### ave_chatwoot_api

- [ ] MongoDB accesible
- [ ] `config/PROD.json` con URL y token de Chatwoot produccion
- [ ] API key insertada en MongoDB
- [ ] Secret `GCP_SA_KEY` en GitHub (si se usa Cloud Run)
- [ ] Health check: `GET /ping` responde OK

### bot_ave

- [ ] `apiUrl` apuntando a `ave_chatwoot_api` de produccion
- [ ] `CHATWOOT_API_URL` apuntando al Chatwoot de produccion
- [ ] `CHATWOOT_TOKEN` de produccion
- [ ] `CHATWOOT_AUTO_ASSIGN` configurado segun necesidad
- [ ] `CHATWOOT_ASSIGN_AGENT_ID` o `CHATWOOT_ASSIGN_TEAM_ID` con IDs validos
- [ ] Meta (WhatsApp) tokens de produccion configurados
- [ ] MongoDB URI de produccion
