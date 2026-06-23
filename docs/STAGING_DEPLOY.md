# Staging InboxHub + Panel AI en Dokploy

Entorno paralelo para validar **fork → GitHub → Dokploy build** sin tocar producción.

| Entorno | Chatwoot | Panel AI | Red Docker |
|---------|----------|----------|------------|
| Producción | `inbox.paluhub.com` | `ainbox.paluhub.com` | `main-chatwoot-miwnzk` |
| **Staging** | `test.inbox.paluhub.com` | `test.ainbox.paluhub.com` | `main-chatwoot-staging` |

## Archivos del fork

- `docker-compose.staging.yml` — build desde `docker/Dockerfile`, imagen `inboxhub/chatwoot:staging`
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
6. **Deploy** (primer build: **30–60 min**)

### Error: `chatwoot-postgres is unhealthy`

Causa habitual: **no configuraste variables en Dokploy**. El log dirá:
`Database is uninitialized and superuser password is not specified`.

1. Pega las variables del paso 4 (incluye `POSTGRES_PASSWORD=...`)
2. Si ya falló un deploy, en Dokploy elimina el volumen `staging-chatwoot-postgres-data` o redeploy limpio
3. Vuelve a desplegar

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

Si pasan 1–4, el pipeline **fork → GitHub → Dokploy build** está validado.

## Recursos estimados (staging)

| Fase | Tiempo | RAM pico |
|------|--------|----------|
| Primer build Chatwoot | 30–60 min | 2–4 GB |
| Build Panel AI | 5–10 min | ~1–2 GB |
| Redeploys (caché) | 8–20 min | Menor |
| Disco extra | ~5–8 GB | — |

## Promoción a producción (después de validar)

1. Backup completo prod (Postgres + `chatwoot-storage`).
2. En app **producción** Chatwoot: cambiar compose a build desde fork (adaptar `docker-compose.staging.yml` a dominios prod) o reutilizar imagen probada.
3. **Reutilizar volúmenes prod** (`chatwoot-postgres-data`, etc.) — no los `staging-*`.
4. `FRONTEND_URL=https://inbox.paluhub.com`, quitar `DEPLOYMENT_ENV=staging`.
5. Panel AI prod: actualizar solo si hace falta; red `main-chatwoot-miwnzk`.
6. Smoke test en prod antes de apagar staging.

## Qué no incluye esta fase

- GitHub Actions obligatorio (Dokploy build desde repo)
- Cambios grandes de UI (colores, resúmenes Panel AI en CW)
- Migración de datos prod → staging (staging empieza vacío a propósito)
- Tocar volúmenes o compose de producción
