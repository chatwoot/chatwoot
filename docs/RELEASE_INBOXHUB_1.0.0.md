# Release InboxHub 1.0.0 — checklist producción

**Versión fork:** `1.0.0` (`PALUHUB_VERSION`)  
**Tag:** `inboxhub-v1.0.0`  
**Rama deploy:** `develop`  
**Base Chatwoot:** `4.15.1`  
**Guía volúmenes / backup:** [`PRODUCTION_MIGRATION.md`](PRODUCTION_MIGRATION.md)  
**Versionado:** [`VERSIONING.md`](VERSIONING.md)

---

## 0. Antes de tocar prod

- [ ] Backup Postgres: `pg_dump` comprimido con fecha.
- [ ] Anotar volumen Postgres actual (`docker inspect` / Dokploy) — **no cambiar nombre de volumen**.
- [ ] Confirmar SHA de la imagen a desplegar = commit del tag `inboxhub-v1.0.0`.
- [ ] Ventana de mantenimiento breve (migrate + restart).

---

## 1. Código a incluir

Merge `feat/internal-tasks` → `develop` (si aún no está), luego tag:

```powershell
git checkout develop
git pull origin develop
git merge --no-ff feat/internal-tasks -m "merge: feat/internal-tasks for InboxHub 1.0.0"
git push origin develop
git tag -a inboxhub-v1.0.0 -m "InboxHub 1.0.0 — Internal Tasks, UX, team RR"
git push origin inboxhub-v1.0.0
```

Dokploy / GHCR debe construir desde `develop` (o el SHA del tag).

---

## 2. Migraciones (obligatorio)

Cuatro migraciones nuevas:

| Timestamp | Tabla / cambio |
|-----------|----------------|
| `20260709120000` | `task_templates` |
| `20260709120100` | `internal_tasks` |
| `20260709120200` | `internal_task_events` |
| `20260709130000` | `internal_tasks.source_message_id` |

Tras levantar la nueva imagen (Rails):

```bash
# En el contenedor rails de prod (nombres según Dokploy)
bundle exec rails db:migrate
bundle exec rails db:migrate:status | tail -20
```

Verificar tablas:

```bash
bundle exec rails runner "puts %w[task_templates internal_tasks internal_task_events].map { |t| [t, ActiveRecord::Base.connection.table_exists?(t)] }.inspect"
```

Si el boot ya corre `db:chatwoot_prepare` / migrate, confirmar en logs que las 4 quedaron `up`.

### Seed plantillas (recomendado una vez)

```bash
bundle exec rails internal_tasks:seed_templates
```

---

## 3. Post-deploy smoke

| # | Prueba | OK |
|---|--------|----|
| 1 | Login `inbox.paluhub.com` | ☐ |
| 2 | Sidebar **Tasks** (BETA) → lista + kanban | ☐ |
| 3 | Abrir una tarea → sidebar Tasks sigue marcado | ☐ |
| 4 | Crear tarea desde conversación; claim / nota sin titileo de toda la lista | ☐ |
| 5 | Asignar conversación a un **equipo** con agentes online → team + un agente | ☐ |
| 6 | Header: split Assign to me / chevron agentes | ☐ |
| 7 | Lista expandida: canal legible; bulk ES una línea | ☐ |
| 8 | WhatsApp menú interactivo (botones nativos) si aplica | ☐ |

---

## 4. Rollback

1. Redeploy imagen GHCR del SHA **anterior** al tag.
2. Migraciones: solo rollback si las tablas están vacías / sin uso:

```bash
bundle exec rails db:rollback STEP=4   # solo si es seguro
```

Si ya hay tareas reales en prod, **no** hagas rollback de schema: deja tablas y vuelve solo la imagen (código viejo ignora tablas nuevas).

---

## 5. Panel AI

Este release es **solo Chatwoot / InboxHub**. Panel AI (`ainbox`) no requiere deploy acoplado salvo que quieras menús WA ya en `develop`/`master` del panel.

---

## 6. Registro

| Campo | Valor |
|-------|-------|
| Fecha deploy | |
| SHA imagen | |
| Quién | |
| Notas | |
