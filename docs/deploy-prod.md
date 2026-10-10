# Despliegue en producción

Stack: `docker-compose.prod.yaml`. Usa una imagen ya construida (sin `build:`) y los servicios compartidos del servidor: `postgres_postgres-vector` y `redis_redis`, en la red `network_public`.

## Variables

Se leen desde un archivo de entorno en el servidor (`QEVA_ENV_FILE`, por defecto `.env.prod`). Ese archivo no se commitea.

| Variable | Descripción |
| --- | --- |
| `QEVA_DOMAIN` | Dominio público, sin protocolo. Por defecto `crm.qeva-ai.com`. Requiere un registro DNS `A` apuntando al servidor. |
| `QEVA_IMAGE` | Imagen publicada en el registro, por ejemplo `ghcr.io/<owner>/qeva-crm:<tag>`. |
| `SECRET_KEY_BASE` | Clave de Rails. Generar una nueva, no reutilizar la de Chatwoot. |
| `POSTGRES_HOST` | `postgres_postgres-vector` |
| `POSTGRES_PORT` | `5432` |
| `POSTGRES_DATABASE` | `chatwoot_qeva` |
| `POSTGRES_USERNAME` | `chatwoot_qeva` |
| `POSTGRES_PASSWORD` | Contraseña de `chatwoot_qeva`, guardada en `~/.config/qeva/chatwoot-db.env` |
| `REDIS_URL` | `redis://:<password>@redis_redis:6379` |
| `REDIS_PASSWORD` | Contraseña de Redis compartido |
| `MAILER_SENDER_EMAIL`, `SMTP_*`, `MAILER_INBOUND_EMAIL_DOMAIN` | Configuración de correo |

## Antes del primer deploy

1. Confirmar el dominio (`QEVA_DOMAIN`).
2. Publicar la imagen en el registro, construida fuera del servidor.
3. Crear `.env.prod` en el servidor con los valores de arriba (permisos 600).
4. Validar la configuración sin levantar nada:

   ```bash
   QEVA_ENV_FILE=/dev/null QEVA_IMAGE=x QEVA_DOMAIN=example.com \
     docker compose -f docker-compose.prod.yaml config -q
   ```

5. Correr las migraciones una sola vez contra `chatwoot_qeva` antes de levantar `qeva_app` y `qeva_worker`.

## Notas

- El límite de memoria es 1 GB por servicio. El stack de Chatwoot de producción tiene 512 MB y se reinicia bajo carga.
- No reutilizar la base `chatwoot` ni sus credenciales.
