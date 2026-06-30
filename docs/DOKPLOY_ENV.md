# Variables de entorno en Dokploy (Chatwoot / InboxHub)

## Capas en Dokploy Compose

1. **Environment (proyecto)** — secrets y config compartida (`env_file: .env` en rails, sidekiq, postgres).
2. **Environment (servicio)** — opcional; p. ej. override de imagen solo en rails/sidekiq.

## Producción

### Proyecto (obligatorio)

Copiar [`.env.production.project.example`](../.env.production.project.example) en **Dokploy → Environment (proyecto)**.

Incluye `CHATWOOT_IMAGE_TAG` pinneada (ej. `develop-0eca20d20`), `SECRET_KEY_BASE`, `POSTGRES_PASSWORD`, `FRONTEND_URL`, SMTP, etc.

### Servicio (opcional)

Si preferís no poner la imagen a nivel proyecto, en **chatwoot-rails** y **chatwoot-sidekiq**:

```env
CHATWOOT_IMAGE_TAG=ghcr.io/pabloluna3596afk/chatwoot:develop-<SHA>
```

## Staging

Proyecto: [`.env.staging.example`](../.env.staging.example)  
Compose: `docker-compose.staging.yml`  
Imagen: `ghcr.io/pabloluna3596afk/chatwoot:develop` (flotante, OK para pruebas)

## Compose por entorno

| Entorno | Compose | Rama repo | Red Docker |
|---------|---------|-----------|------------|
| Staging | `docker-compose.staging.yml` | `develop` | `main-chatwoot-staging` |
| Producción | `docker-compose.production.yml` | `develop` | `main-chatwoot-prod` |

## Escapado

Passwords con `$` → `$$` en Dokploy.
