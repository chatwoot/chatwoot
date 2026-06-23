# Prueba local: widget Chatwoot + Panel AI

## 1. Levantar stacks

```powershell
docker network create main-chatwoot-local

cd D:\DOCUMENTOS\GITHUB\chatwoot\chatwoot
docker compose -f docker-compose.dokploy.yml up -d

cd D:\DOCUMENTOS\GITHUB\chatwoot\panel-ai
docker compose -f docker-compose.yml -f docker-compose.local.yml up -d --build
```

- Chatwoot: http://localhost:3000
- Panel AI UI: http://localhost:3010
- Panel AI API: http://localhost:8010/docs

## 2. Widget (página de prueba)

```powershell
cd D:\DOCUMENTOS\GITHUB\chatwoot\chatwoot
python -m http.server 8080
```

Abrir: http://localhost:8080/test-chat.html

En Chatwoot → **Settings → Inboxes → Website → Configuration**:

| Campo | Valor |
|-------|--------|
| Website URL | `http://localhost:8080` |
| Allowed domains | `http://localhost:8080` |

En **Installation**, copia `websiteToken` a `test-chat.html` si cambiaste de inbox.

**Error común:** poner `baseUrl` en `8080`. Debe ser **`http://localhost:3000`** (Chatwoot).

## 3. Webhook Panel AI (formulario Chatwoot)

En **Settings → Integrations → Webhooks**, URL válida en Windows + Docker:

```text
http://host.docker.internal:8010/api/chatwoot/webhook
```

Eventos: `message_created` (y `conversation_created` si está disponible).

**No uses** `http://backend:8000/...` en el formulario (Chatwoot lo rechaza).

Desde contenedores en la misma red Docker, Panel AI también acepta:

```text
http://backend:8000/api/chatwoot/webhook
```

(pero eso se configura en Panel AI / API, no en el UI de Chatwoot).

## 4. Panel AI

1. Login Super Admin: http://localhost:3010 (`admin@admin.com` / ver `.env`)
2. Chatwoot config: `api_url` = `http://chatwoot-rails:3000`
3. Sync inboxes + vincular **Assistant** al inbox Website
4. `CHATWOOT_API_TOKEN` en `panel-ai/.env` = token de Chatwoot (Profile → Access Token)

## 5. Probar

1. Abre `test-chat.html` y escribe **Hola**
2. Debe responder el bot en el widget
3. Logs: `docker logs panel-ai-backend-1 --tail 50 -f`
