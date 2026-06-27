# Migración Chatwoot producción → fork (GHCR)

Guía para promover `ghcr.io/pabloluna3596afk/chatwoot:develop` a **producción** sin perder datos.

## Incidente staging (2026-06-26) — lección aprendida

**Síntoma:** onboarding de admin otra vez en `test.inbox.paluhub.com`.

**Causa real:** no fue el fork ni `db:chatwoot_prepare`. Postgres montó un **volumen nuevo vacío** (`…_chatwoot-postgres-data`, PG14, creado el día del deploy) en lugar del volumen con datos (`…_staging-chatwoot-postgres-data`, PG16).

**Causas contribuyentes:**
1. Dokploy usaba `docker-compose.yml` generado, **no** `docker-compose.staging.yml` del repo.
2. Nombres de volumen distintos (`chatwoot-postgres-data` vs `staging-chatwoot-postgres-data`).
3. Cambio de imagen Postgres (pg14 ↔ pg16) sin reutilizar el mismo volumen.

**Producción no afectada:** `main-chatwoot-miwnzk` siguió en `chatwoot/chatwoot:v4.14.2` con volumen `main-chatwoot-miwnzk_chatwoot-postgres-data`.

---

## Regla de oro

> **Cambiar solo `image:` no borra datos. Cambiar el nombre del volumen de Postgres sí.**

Antes de cada redeploy, anotar qué volumen monta Postgres:

```bash
sudo docker inspect <app>-chatwoot-postgres-1 --format '{{range .Mounts}}{{.Name}}{{end}}'
sudo docker exec <app>-chatwoot-postgres-1 psql -U postgres -d chatwoot -c 'SELECT count(*) FROM accounts;'
```

Si `accounts = 0` y no es instalación nueva → **detener y corregir volumen antes de seguir**.

---

## Checklist pre-migración (producción)

### 1. Backup obligatorio

```bash
# En el VPS — reemplazar nombres según app Dokploy prod
APP=main-chatwoot-miwnzk
sudo docker exec ${APP}-chatwoot-postgres-1 pg_dump -U postgres chatwoot | gzip > ~/backup-chatwoot-prod-$(date +%F).sql.gz
# Opcional: snapshot del volumen storage
```

### 2. Inventario de volúmenes prod (anotar en ticket)

| Servicio | Volumen Dokploy esperado | Verificado |
|----------|--------------------------|------------|
| Postgres | `main-chatwoot-miwnzk_chatwoot-postgres-data` | ☐ |
| Redis | `main-chatwoot-miwnzk_chatwoot-redis-data` | ☐ |
| Storage | `main-chatwoot-miwnzk_chatwoot-storage` | ☐ |

```bash
sudo docker volume ls | grep main-chatwoot-miwnzk
sudo docker exec main-chatwoot-miwnzk-chatwoot-postgres-1 psql -U postgres -d chatwoot -c 'SELECT count(*) FROM accounts;'
```

**No tocar** volúmenes `staging-*` ni `saas-chatwoottest-*`.

### 3. Variables que NO deben cambiar en prod

- `POSTGRES_PASSWORD` (mismo password → mismo volumen)
- `SECRET_KEY_BASE` (si cambia, sesiones invalidadas; no causa onboarding)
- Nombres de volumen en compose

### 4. Cambio permitido en prod (solo imagen)

En Dokploy → app **producción** Chatwoot (`main-chatwoot-miwnzk`):

```yaml
image: ghcr.io/pabloluna3596afk/chatwoot:develop
pull_policy: always
```

**Mantener sin cambios:**
- `chatwoot-postgres-data` (Dokploy lo prefija → `main-chatwoot-miwnzk_chatwoot-postgres-data`)
- `chatwoot-redis-data`, `chatwoot-storage`
- Postgres `pgvector/pgvector:pg14` (misma major que hoy)
- Red `main-chatwoot-miwnzk` / `dokploy-network`

### 5. Post-deploy verificación (antes de dar por bueno)

```bash
sudo docker exec main-chatwoot-miwnzk-chatwoot-postgres-1 psql -U postgres -d chatwoot -c 'SELECT count(*) FROM accounts;'
# Debe ser el mismo número que antes (ej. 2)
```

- Login en `inbox.paluhub.com` sin onboarding
- Conversaciones e inboxes visibles
- Sidekiq sin errores en logs

### 6. Panel IA producción

| Acción | ¿Necesario al cambiar solo imagen Chatwoot? |
|--------|---------------------------------------------|
| Redeploy Panel IA | **No**, si Chatwoot conserva mismos tokens/cuentas |
| Actualizar `CHATWOOT_API_TOKEN` | **Solo si** re-onboarding o token revocado |
| Re-sync webhook Super Admin | **Solo si** URL/secret cambió |

**Sí redeploy Panel IA** cuando subas código MVP en `panel-ai` `master` (independiente del fork Chatwoot).

---

## Orden recomendado de despliegue completo

1. Backup prod Chatwoot + Panel IA
2. **Staging** Chatwoot (validar fork + volúmenes correctos)
3. **Staging** Panel IA (`docker-compose.staging.yml`, rama `master`)
4. Smoke test staging (bot, guardian, menús)
5. **Prod** Panel IA redeploy (`master`)
6. **Prod** Chatwoot — solo cambio `image:` + redeploy
7. Smoke test prod

---

## Recuperación staging (volumen equivocado)

Si los datos están en `saas-chatwoottest-4bjduc_staging-chatwoot-postgres-data` (PG16):

1. Parar app staging en Dokploy (no eliminar volúmenes)
2. En compose de Postgres:
   - volumen: `staging-chatwoot-postgres-data`
   - imagen: `pgvector/pgvector:pg16`
3. Redeploy
4. Verificar `SELECT count(*) FROM accounts;` > 0
5. Si no recupera: onboarding limpio + nuevo token en Panel IA staging + redeploy Panel IA

---

## Dokploy: errores frecuentes

| Error | Prevención |
|-------|------------|
| Compose file incorrecto | Staging → `docker-compose.staging.yml`; Prod → compose actual con volúmenes `chatwoot-*` |
| Postgres unhealthy → borrar volumen | **Nunca** borrar volumen sin backup; corregir `POSTGRES_PASSWORD` en .env |
| Onboarding tras deploy | Verificar volumen montado y count de accounts |
| Puertos Qdrant 6333 | Panel staging no usa `docker-compose.yml` de prod |

---

## Rollback producción

1. Dokploy → imagen `chatwoot/chatwoot:v4.14.2`
2. Redeploy (mismos volúmenes)
3. Verificar accounts count

Los datos siguen en el volumen; el rollback es seguro si no se borró el volumen.
