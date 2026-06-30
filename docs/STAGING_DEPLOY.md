# Staging InboxHub + Panel AI en Dokploy

Entorno paralelo para validar **fork → GitHub Actions → GHCR → Dokploy pull** sin tocar producción.

| Entorno | Chatwoot | Panel AI | Red Docker |
|---------|----------|----------|------------|
| Producción | `inbox.paluhub.com` | `ainbox.paluhub.com` | `main-chatwoot-miwnzk` |
| **Staging** | `test.inbox.paluhub.com` | `test.ainbox.paluhub.com` | `main-chatwoot-staging` |

## Archivos del fork

- `docker-compose.staging.yml` — pull de `ghcr.io/pabloluna3596afk/chatwoot:develop` (sin build en VPS)
- `.github/workflows/chatwoot-docker.yml` — compila y publica la imagen en GHCR al push a `develop`
- `.env.staging.example` — plantilla de variables (copiar a `.env` en Dokploy)
- `public/brand-assets/logo*.svg` — logos PaluHub
- Login: badge **Entorno de pruebas — InboxHub** si `DEPLOYMENT_ENV=staging`

Panel AI (repo hermano):

- `docker-compose.staging.yml`
- `.env.staging.example`

## A. Preparación en el VPS (5 min)

**No modificar** las apps de producción existentes.

```bash
docker network create main-chatwoot-staging
```

DNS (registros A hacia la IP del VPS **157.137.211.152**):

- `test.inbox.paluhub.com`
- `test.ainbox.paluhub.com`

SSH al VPS (Oracle):

```bash
ssh -i "ruta/a/ssh-key-2026-05-06.key" ubuntu@157.137.211.152
```

## B. App Chatwoot Staging

1. Dokploy → **Nueva aplicación** → Compose
2. Repositorio: `pabloluna3596afk/chatwoot`, rama `develop`
3. Compose file: `docker-compose.staging.yml`
4. **Environment / Variables** (obligatorio — sin esto Postgres queda `unhealthy`):
   - Copiar **todo** `.env.staging.example`
   - Reemplazar cada `CHANGE_ME` (mínimo: `SECRET_KEY_BASE`, `POSTGRES_PASSWORD`)
   - `POSTGRES_PASSWORD` no puede estar vacío
5. Dominio: `test.inbox.paluhub.com`
6. **Deploy** (~2–5 min en VPS; el build pesado corre en **GitHub Actions**, 5–25 min)

### Imagen Docker (GHCR)

| Tag | Uso |
|-----|-----|
| `ghcr.io/pabloluna3596afk/chatwoot:develop` | Staging (compose actual) |
| `ghcr.io/pabloluna3596afk/chatwoot:staging` | Alias del mismo build |

Tras cada `push` a `develop`, espera que **Build and Push Docker Image** termine en verde en GitHub Actions antes de redeploy en Dokploy.

La imagen incluye **amd64 + arm64** (Oracle Cloud Ampere usa arm64). El primer build multi-arch puede tardar **15–30 min** en GitHub.

Si el pull falla por permisos GHCR: en Dokploy → **Registry** → `ghcr.io` con PAT (`read:packages`) o haz el paquete **Public** en GitHub Packages.

### Error: `chatwoot-postgres is unhealthy`

Causa habitual: **no configuraste variables en Dokploy**. El log dirá:
`Database is uninitialized and superuser password is not specified`.

1. Pega las variables del paso 4 (incluye `POSTGRES_PASSWORD=...`)
2. Si ya falló un deploy, en Dokploy elimina el volumen `staging-chatwoot-postgres-data` **solo si no tiene datos que quieras recuperar** — siempre hacer backup antes
3. Vuelve a desplegar

### Error: onboarding otra vez tras cambiar imagen (incidente 2026-06-26)

**No es el fork.** Postgres quedó montado en un volumen **nuevo vacío** (`…_chatwoot-postgres-data`) en vez del volumen con datos (`…_staging-chatwoot-postgres-data`).

**Prevención en Dokploy:**
- Compose file: **`docker-compose.staging.yml`** (no el `docker-compose.yml` que Dokploy genera solo con `chatwoot-postgres-data`)
- Antes de redeploy: `SELECT count(*) FROM accounts;` debe ser > 0 si ya había onboarding

Ver recuperación y plan prod: [`docs/PRODUCTION_MIGRATION.md`](./PRODUCTION_MIGRATION.md)

Servicios expuestos en la red `main-chatwoot-staging`:

- `chatwoot-rails:3000`
- `chatwoot-postgres:5432`

## C. App Panel AI Staging

1. Dokploy → **Nueva aplicación** → Compose
2. Repositorio Panel AI, rama `develop`
3. Compose file: `docker-compose.staging.yml`
4. Variables: copiar desde `.env.staging.example`
   - `CHATWOOT_DATABASE_URL` debe usar el **mismo** `POSTGRES_PASSWORD` de Chatwoot staging
   - `CHATWOOT_API_TOKEN` → se obtiene después del onboarding (paso D)
5. Dominio: `test.ainbox.paluhub.com`
6. **Deploy** (~5–10 min)

**Importante:** el compose debe ser solo `docker-compose.staging.yml`. Si Dokploy usa `docker-compose.yml`, Qdrant intentará el puerto **6333** ya ocupado por producción.

### Error: `Bind for 0.0.0.0:6333 failed: port is already allocated`

Producción (`main-panelai-sa7dgb`) ya usa el puerto 6333. Staging **no debe publicar puertos** en el host.

1. En Dokploy → Compose file: **`docker-compose.staging.yml`** (no `docker-compose.yml`)
2. Redeploy
3. Qdrant solo se usa dentro de la red Docker (`http://qdrant:6333`)

Orden recomendado: **Chatwoot staging primero**, luego Panel AI.

## D. Integración Chatwoot ↔ Panel AI

1. Abrir `https://test.inbox.paluhub.com` y completar onboarding (cuenta admin nueva).
2. En Chatwoot staging: **Profile → Access Token** → crear token API.
3. Pegar token en Panel AI staging: `CHATWOOT_API_TOKEN`.
4. Redeploy Panel AI si cambiaste el token.
5. Super Admin Panel AI → Chatwoot → sync + webhook:
   - URL interna: `http://backend:8000/api/chatwoot/webhook`
6. Enviar mensaje de prueba en un inbox de Chatwoot staging.

## Checklist de validación (determinante)

| # | Prueba | Éxito si… |
|---|--------|-------------|
| 1 | Logo en login | Muestra **logo PaluHub** (no Chatwoot) |
| 2 | Título + badge | "Login to **InboxHub**" + línea ámbar *Entorno de pruebas* |
| 3 | Pestaña navegador | Título **InboxHub** |
| 4 | Producción intacta | `inbox.paluhub.com` sin cambios |
| 5 | Panel AI staging | Login y dashboard en `test.ainbox.paluhub.com` |
| 6 | Bot / webhook | Respuesta automática en inbox staging |

Si pasan 1–4, el pipeline **fork → GitHub Actions → GHCR → Dokploy pull** está validado.

## Recursos estimados (staging)

| Fase | Tiempo | Dónde |
|------|--------|--------|
| Build Chatwoot (GH Actions) | 5–25 min | GitHub (no toca VPS) |
| Deploy Dokploy (pull + up) | 2–5 min | VPS Oracle |
| Build Panel AI | 5–10 min | VPS |
| Disco extra | ~5–8 GB | VPS |

## Promoción a producción (después de validar)

Ver guía completa: **[`docs/PRODUCTION_MIGRATION.md`](./PRODUCTION_MIGRATION.md)**

**Producción nueva (fresh start, recomendado):**

1. Crear red `main-chatwoot-prod` en el VPS.
2. Nueva app Dokploy Chatwoot → `docker-compose.production.yml` + [`.env.production.project.example`](../.env.production.project.example).
3. Fijar `CHATWOOT_IMAGE_TAG` al SHA validado en staging (ej. `develop-0eca20d20`).
4. Onboarding → API token → nueva app Panel AI (`master`, `docker-compose.production.yml`).
5. Env Dokploy: [DOKPLOY_ENV.md](./DOKPLOY_ENV.md) — proyecto vs servicio `frontend`.
6. Smoke test → cutover DNS `inbox` / `ainbox`.

**Legacy (migrar datos existentes en `main-chatwoot-miwnzk`):** ver sección "Migración del stack legacy" en PRODUCTION_MIGRATION.md.

## Qué no incluye esta fase

- Cambios grandes de UI (colores, resúmenes Panel AI en CW)
- Migración de datos prod → staging (staging empieza vacío a propósito)
- Tocar volúmenes o compose de producción
