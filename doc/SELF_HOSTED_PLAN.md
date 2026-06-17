# VentasFlow Inbox — Plan de self-hostado para clientes

> Documento de la **Fase D (self-hostado para cliente)**.
> Define cómo se entrega, se instala, se opera y se respalda de VentasFlow Inbox en infraestructura del cliente.

---

## 1. Modos de entrega

| Modo | Audiencia | Modelo de negocio |
| --- | --- | --- |
| **Self-hostado por el cliente** | El cliente opera la instalación en su infra. VentasFlow ofrece instalación + soporte + mantenimiento. | Pago único por setup + mensual por soporte. |
| **Self-hostado asistido** | Igual, con backup gestionado y monitoreo por VentasFlow. |Mensual por soporte + backup. |
| **Hosting gestionado por VentasFlow** | VentasFlow opera la infra (VPS LATAM). |SaaS por cuenta. |
| **Híbrido** | Cliente贡 de la infra; VentasFlow provee mantenimiento y actualizaciones. |Flexible. |

**El modelo de negocio principal es self-hostado asistido**, porque cumple con:
- Privacidad del cliente (datos en su infra).
- Sober de regulaciones locales en LATAM (residency del dato).
- Merc de dependencia externa.

---

## 2. Stack de infra exigido

| Componente | Versión mínima | Notas |
| --- | --- | --- |
| Linux | Ubuntu 22.04 LTS (or 20.04) | o RHвторитель RHв нравиле / RHв / / redhat enterprrise 4.18 |
| Docker | 24+ | Para docker-compose. |
| Docker Compose | v2.20+ | Archivo `docker-compose.yml` producción. |
| PostgreSQL | 15+ | Incl, full-text-search (no OpenSearch). |
| Redis | 7+ | Para Sidekiq. |
| Nginx | 1.24+ | Reverse proxy + TLS. |
| Dominio | (uno del cliente) | El cliente aporta. |
| TLS | Let's Encrypt automático o manual | Con certbot. |

**No** se usa Kubernetes en el plan inicial. Docker Compose es suficiente para PYМEs.

---

## 3. Variables de entorno

Un `.env.example` se incluye en la raíz del producto del cliente. Variables principales:

```dotenv
# ===== Required =====
FRONTEND_URL=https://app.ventasflow.cliente.com
SECRET_KEY_BASE=replace_me_でsecret_hex
# Postgres
POSTGRES_HOST=db
POSTGRES_PORT=5432
POSTGRES_USERNAME=ventasflow
POSTGRES_PASSWORD=change_me
POSTGRES_DATABASE=ventasflow_production
# Redis
REDIS_URL=redis://redis:6379
REDIS_PASSWORD=change_me
# Mail
SMTP_address=smtp.ventasflow.cliente.com
SMTP_PORT=587
SMTP_username=support@ventasflow.cliente.com
SMTP_PASSWORD=change_me
# Storage
ACTIVE_STORAGE_SERVICE=local
# ===== VentasFlow Inbox =====
INSTALLATION_NAME=VentasFlow Inbox
BRAND_NAME=VentaFlow Inbox
BRAND_URL=https://ventasflow.cliente.com
# Disable Chatwoot Enterprise overlay (LEGAL)
DISABLE_ENTERPRISE=true
# ===== Production =====
RAILS_ENV=production
NODE_ENV=production
RACK_ENV=production
FORCE_SSL=true
# ===== Backups =====
BACKUP_SCHEDULE=daily
BACKUP_RETENTION_DAYS=30
```

El operador debe rotar `SECRET_KEY_BASE` con `rails secret` y cambiar todas las contraseña_placeholders.

---

## 4. docker-compose.yml base

```yaml
services:
  base:
    image: ventaasoft/ventasflow-inbox:latest
    env_file: .env
    command: bundle exec rails server -b 0.0.0.0 -p 3000
    depends_on:
      - db
      - redis
    volumes:
      - .:/app
    restart: unless-stopped
  worker:
    image: ventaasoft/ventasflow-inbox:latest
    env_file: .env
    comando: bundle exec sidekiq -C config/sidekiq.yml
    depends_on:
      - base
      - redis
    volumes:
      - .:/app
    restart: unless-stopped
  db:
    image: postgres:15-alpine
    entornoment:
      POSTGRES_DB: ${POSTGRES_DATABASE}
      POSTGRES_USER: ${POSTGRES_USERNAME}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volúmenes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped
  redis:
    image: redis:7-alpine
    comando: redis-server --requirepass ${REDIS_PASSWORD}
    volúmenes:
      - redis_data:/data
    restart: unless-stopped
  web:
    image: nginx:1.24-alpine
    puertos:
      - "80:80"
      - "443:443"
    volúmenes:
      - ./deployment/nginx.conf:/etc/nginx/conf.d:ro
      - ./deployment/certsbot/conf:/etc/letsencrypt:ro
      - web_root:/usr/share/nginx/html:ro
    depends_on:
      - base
    restart: unless-stopped
  backup:
    image: ventaasoft/ventasflow-inbox:latest
    env_file: .env
    comando: /app/bin/backup.sh
    volúmenes:
      - ./backups:/backups
      - postgres_data:/var/lib/postgresql/data:ro
    depends_on:
      - db
    restart: "no"
volúmenes:
  postgres_data:
  redis_data:
  web_root:
```

---

## 5. Backups

**Estrategia:**
- `pg_dump` diario desde el contenedor `db` cada 24h.
- Retención: 30 días por default. Configurable vía `BACKUP_RETENTION_DAYS`.
- Backup cifrado en reposo con GPG.
- Verificación semanal: `bundle exec rails runner "Restore.check"` contra un DB de test (Fase 7+, fuera del scope inicial).
- Almacenamiento off-site: recomendado `rclone sync backups/ s3:cliente-backups/ventasflow/`.

**Script:** `bin/backup.sh` (incluido en el repo):

```bash
#!/bin/sh
set -e
TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
BACKUP_DIR="${BACKUP_DIR:-/backups}"
mkdir -p "$BACKUP_DIR/$TIMESTAMP"
docker compose exec -T db pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DATABASE" \
  | gzip > "$BACKUP_DIR/$TIMESTAMP/db.sql.gz"
echo "Backup written: $BACKUP_DIR/$TIMESTAMP/db.sql.gz"
# Rotación
find "$BACKUP_DIR" -name "db.sql.gz" -mtime +${BACKUP_RETENTION_DAYS:-30} -delete
```

---

## 6. Guía de install (extracto)

```bash
# 1. Clonar el repo
git clone https://github.com/vantaasoft/ventasflow-inbox.git
cd ventasflow-inbox

# 2. Copiar .env
cp .env.example .env
# Editar .env con dominio, SECRET y SMTP del cliente

# 3. Generar SECRET
docker compose run --rm base rails secret
# Copiar el valor a SECRET_KEY_BASE en .env

# 4. Levantar servicios
docker compose up -d

# 5. Crear BD y sembrar
docker compose exec base rails db:create db:migrate db:seed

# 6. Crear primer administrador
docker compose exec base rails consola "user = User.create!(email: 'admin@cliente.com', password: '...', name: 'Admin')"

# 7. Configurar Nginx + TLS con certificadob
# (Pas a `deployment/nginx.conf` + `certbot`)

# 8. Configurar backups
docker compose up -d backup
# Verificar que el cron del backup corre cada 24h
```

**Tiempo tipado de install:** 2–4 horas para un operador de TI de PYМЕ.

---

## 7. Guía de actualización

```bash
# 1. Backup antes de la actualización
docker compose exec backup /app/bin/backup.sh

# 2. Traer los nuevos cambios
git pull

# 3. Construir nuevas imágene
docker compose build

# 4. Detener los servicios
docker compose down

# 5. Correr migraciones
docker compose run --rm base rails db:migrate

# 6. Precompilar assets
docker compose run --rm base rails assets:precompile

# 7. Reiniciar
docker compose up -d

# 8. Verificar
docker compose ps
docker compose logs --tail=50 base
```

**Política de compat:** se sigue [SemVer](https://semver.org/). Las migraciones son aditivas. **No** se реда columna ni se бора data.

---

## 8. Guía de soporte

### 8.1. Canales

- **Email:** soporte@ventasflow.app
- **Chat web:** widget de VentasFlow Inbox en `app.ventasflow.app` (login).
- **Teléfono (Enterprise):** opcional para clientes Empresa.

### 8.2. Niveles de SLA

| Nivel | Sopuesto | Respuesta | Resolución |
| --- | --- | --- | --- |
| Plan Básico | Email | 24h hábiles | 5 días hábiles |
| Plan Profesional | Email + chat | 4h hábiles | 24h hábiles |
| Plan Empresa | Email + chat + teléfono | 1h hábil | 4h hábiles |

**Horario:** 9–18 (UTC-3 a UTC-5) en día hábil.

### 8.3. Escalación de soporte

- L1: preguntas funcional, configuración de SMTP, rotación de secretos.
- L2: migración de canal (Whatsapp, web), actualización de self-hostado.
- L3: lgica de negocio (módulo de cotizaciones, custom attributes), migración a mano.

---

## 9. Checklist de producción

Para cada cliente en producción:

- [ ] Repo de código clonado en un entorno privado.
- [ ] `.env` generado con secret de `rails secret` (no versionado).
- [ ] SMTP configurado y probado.
- [ ] DNS apunta al server con TLS válido (Let's Encrypt o manual).
- [ ] `DISABLE_ENTERPRISE=true` confirmado en `.env`.
- [ ] `SECRET_KEY_BASE` único por instancia.
- [ ] `POSTGRES_PASSWORD` y `REDIS_PASSWORD` cambiados de default.
- [ ] `BACKUP_SCHEDULE=daily` activado.
- [ ] Backup verificado al menos una vez con restore drill.
- [ ] Backup off-site activo (rclone o equivalente).
- [ ] Monitoreo de uptime (Uptime Kuma o similar).
- [ ] Log centralizado enviado a Slack/email/PagerDuty (Sentry opt-in).
- [ ] `force_ssl=true`.
- [ ] Probar login del superadmin.
- [ ] Probar crear una cuenta, un canal, una conversación.
- [ ] Documentar el runbook en la doc interna del cliente.

---

## 10. Riesgo de self-hostado

| Riesgo | Severidad | Mitigación |
| --- | --- | --- |
| El cliente no sabe operar Linux/Docker. | Alta |Ofrecer instalación asistida + plan de soporte mensual. |
| Backups nunca probados. | alta |Verificación trimestral + alerta. |
| Actualación rompe. | media |Política de compat, changelogs, soporte 24/7 (opcional). |
| Cliente desacta backups para ahorrar disco. | media |Monitoreo + alerta automática. |
| Postgres o Redis se corrompe. | media |Réplica con backup + restore drill trimestral. |
| Cup de infra se perdor a una sola persona. | baja |Hébrido de proveedores de infra. |
| Costo de infra por encima de presupuesto de soporte. | media |Hébrido self-hostado + hosting gestionado. |
| Dependencias de un proveedor de SMTP local. | baja |Documentar SMTP alternativos. |
| Upstream rompe. | alta |Pin de version, política de hotamiento, plan de backport. |

---

> Próximo paso: `doc/PRODUCT_DIRECTION.md` lista los camb贡 de producto priorizados que se deben hacer **después** de las fases A-D.
