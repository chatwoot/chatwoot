# Prueba local: widget Chatwoot + Panel AI

## 1. Levantar stacks

```powershell
docker network create main-chatwoot-local

# Paridad con staging: imagen fork (NO chatwoot/chatwoot upstream)
cd D:\DOCUMENTOS\GITHUB\chatwoot\panel-ai
python scripts/sync-local-to-staging.py

# O manual:
cd D:\DOCUMENTOS\GITHUB\chatwoot\chatwoot
docker compose -f docker-compose.dokploy.yml -f docker-compose.local.yml pull
docker compose -f docker-compose.dokploy.yml -f docker-compose.local.yml up -d

cd D:\DOCUMENTOS\GITHUB\chatwoot\panel-ai
git checkout develop && git pull origin develop
docker compose -f docker-compose.yml -f docker-compose.local.yml up -d --build
```

- Chatwoot: http://localhost:3000
- Panel AI UI: http://localhost:3010
- Panel AI API: http://localhost:8010/docs

## 2. Widget (página de prueba)

Con el stack local levantado, **nginx en :8080** sirve la página automáticamente:

```powershell
cd D:\DOCUMENTOS\GITHUB\chatwoot\chatwoot
docker compose -f docker-compose.dokploy.yml -f docker-compose.local.yml up -d widget-test
```

Abrir: http://localhost:8080/test-chat.html

Alternativa manual (sin Docker): `python -m http.server 8080` en la carpeta `chatwoot/`.

En Chatwoot → **Settings → Inboxes → Website → Configuration**:

| Campo | Valor |
|-------|--------|
| Website URL | `http://localhost:8080` |
| Allowed domains | `http://localhost:8080` |

En **Installation**, copia `websiteToken` a `test-chat.html` si cambiaste de inbox.

**Error 429 en `/widget`:** Chatwoot limita el widget a 5 cargas/hora por IP. En local pon en `.env`:

```env
ENABLE_RACK_ATTACK_WIDGET_API=false
```

y recrea los contenedores (un `restart` no recarga `.env`):

```bash
docker compose -f docker-compose.dokploy.yml up -d chatwoot-rails chatwoot-sidekiq
```

## 3. Webhook Panel AI (formulario Chatwoot)

En **Settings → Integrations → Webhooks**, usa la URL **interna de Docker** (misma red `main-chatwoot-local`):

```text
http://panel-ai-backend-1:8000/api/chatwoot/webhook
```

En `.env` de Chatwoot local también necesitas:

```env
SAFE_FETCH_ALLOW_PRIVATE_NETWORK=true
```

y recrear rails + sidekiq (`up -d`, no solo `restart`).

**No uses** `http://host.docker.internal:8010/...` — Chatwoot lo bloquea por SSRF (`has no public ip addresses`).

Eventos: `message_created` (y `conversation_created` si está disponible).

## 4. Panel AI

1. Login Super Admin: http://localhost:3010 (`admin@admin.com` / ver `.env`)
2. Chatwoot config: `api_url` = `http://chatwoot-rails:3000`
3. Sync inboxes + vincular **Assistant** al inbox Website
4. `CHATWOOT_API_TOKEN` en `panel-ai/.env` = token de Chatwoot (Profile → Access Token)

## 5. Probar

1. Abre `test-chat.html` y escribe **Hola**
2. Debe responder el bot en el widget
3. Logs: `docker logs panel-ai-backend-1 --tail 50 -f`

### Ver conversación en Chatwoot

Los chats con bot activo quedan en estado **Pending** (no Open). Hay **dos filtros distintos** llamados "Todos":

| Filtro | Ubicación en UI | Qué controla |
|--------|-----------------|--------------|
| **Mías / Sin asignar / Todos** | Pestañas arriba de la lista | Asignación a agente |
| **Abiertas / Pendientes / Todos** | Icono ⇅ (ordenar) → **Estado** | Estado de la conversación |

Si solo cambias las pestañas a "Todos" pero **Estado = Abiertas** (default), la lista sale vacía aunque el contador muestre `1` en "Sin asignar".

**Para ver el chat del widget:** icono ⇅ → Estado → **Pendientes** o **Todos**.

Acceso directo (ejemplo conversación reciente): `http://localhost:3000/app/accounts/1/conversations/14`

El `404` en `toggle_typing` al abrir el widget es normal si aún no hay conversación; no bloquea el envío de mensajes.

### El mensaje llega a Chatwoot pero el bot no responde (401 webhook)

Panel AI rechaza el webhook si el secret no coincide con el configurado en Chatwoot → Settings → Integrations → Webhooks.

Sincronizar desde la BD local de Chatwoot:

```powershell
cd D:\DOCUMENTOS\GITHUB\chatwoot\panel-ai
python scripts/sync-webhook-secret.py
cd D:\DOCUMENTOS\GITHUB\chatwoot\panel-ai
docker compose -f docker-compose.yml -f docker-compose.local.yml up -d --force-recreate backend
```

Luego envía otro mensaje desde `test-chat.html`.

## 6. Estado visual del bot (Panel IA → Chatwoot)

Panel AI sincroniza el estado del bot en `custom_attributes` de cada conversación. Chatwoot muestra badges en la lista y en la conversación abierta.

**Setup único en Chatwoot** → Settings → Custom Attributes → **Conversation**:

| Key | Tipo |
|-----|------|
| `panel_ia_estado` | Text |
| `panel_ia_estado_label` | Text |

Estados posibles: `activo` (IA contestando), `esperando` (IA esperando), `solicita_ayuda` (IA solicita ayuda).

**Deploy frontend Chatwoot** tras cambios en el fork:

```powershell
cd D:\DOCUMENTOS\GITHUB\chatwoot\chatwoot
Remove-Item -Recurse -Force public/vite/assets, public/vite/.vite -ErrorAction SilentlyContinue
pnpm exec vite build
docker exec chatwoot-chatwoot-rails-1 sh -c "rm -rf /app/public/vite"
docker cp public/vite chatwoot-chatwoot-rails-1:/app/public/vite
docker restart chatwoot-chatwoot-rails-1
```

**Reiniciar Panel AI** tras cambios en el backend del segmento `integrations/chatwoot/state/`.

Hard refresh en el navegador (`Ctrl+Shift+R`) tras el deploy.
