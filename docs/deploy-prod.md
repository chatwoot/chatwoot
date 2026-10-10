# Despliegue en producción

Stack: `docker-compose.prod.yaml` (Portainer / Docker Swarm). Usa una imagen ya construida (sin `build:`) y los servicios compartidos del servidor: `postgres_postgres-vector` y `redis_redis`, en la red `network_public`.

## Variables del stack (no sensibles)

Se cargan en Portainer: *Stacks → Editor → Environment variables*.

| Variable | Descripción |
| --- | --- |
| `QEVA_IMAGE` | Imagen publicada en el registro, por ejemplo `ghcr.io/<owner>/qeva-crm:<tag>`. |
| `QEVA_DOMAIN` | Dominio público, sin protocolo. Por defecto `crm.qeva.xyz`. |

DNS: `crm` en `qeva.xyz` como CNAME a `manager.qeva.xyz`, en modo DNS only.

## Secret único: `qeva_env`

Todos los valores sensibles van en **un solo secret de Swarm** llamado `qeva_env`. Se crea en Portainer: *Secrets → Add secret*, nombre `qeva_env`.

Su contenido es un archivo tipo `.env`, una línea por variable. Los valores con espacios o caracteres especiales van entre comillas dobles:

```
SECRET_KEY_BASE=<clave generada, distinta a la de Chatwoot>
REDIS_URL=redis://:<password>@redis_redis:6379
REDIS_PASSWORD=<password de Redis compartido>
POSTGRES_HOST=postgres_postgres-vector
POSTGRES_PORT=5432
POSTGRES_DATABASE=chatwoot_qeva
POSTGRES_USERNAME=chatwoot_qeva
POSTGRES_PASSWORD=<password de chatwoot_qeva>
MAILER_SENDER_EMAIL="QEVA CRM <no-reply@qeva.xyz>"
SMTP_DOMAIN=gmail.com
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=<usuario SMTP>
SMTP_PASSWORD=<clave SMTP>
SMTP_AUTHENTICATION=plain
SMTP_ENABLE_STARTTLS_AUTO=true
SMTP_OPENSSL_VERIFY_MODE=peer
MAILER_INBOUND_EMAIL_DOMAIN=gmail.com
```

El contenido no se commitea. Las contraseñas de `chatwoot_qeva` están en `~/.config/qeva/chatwoot-db.env` en el servidor.

**Rotar un secret:** los secrets de Swarm son inmutables. Para cambiar el contenido, crear `qeva_env_v2`, cambiar el nombre en `secrets:` del compose y redeployar.

## Antes del primer deploy

1. Publicar la imagen en el registro, construida fuera del servidor.
2. Crear el secret `qeva_env` en Portainer.
3. Crear el stack pegando `docker-compose.prod.yaml` y cargar `QEVA_IMAGE` y `QEVA_DOMAIN`.
4. Validar el compose en local, sin levantar nada:

   ```bash
   QEVA_IMAGE=example/qeva:test docker compose -f docker-compose.prod.yaml config -q
   ```

5. Correr las migraciones una vez contra `chatwoot_qeva` antes de que arranquen `qeva_app` y `qeva_worker`.
6. Activar el webhook del stack en Portainer (*Stack → Webhook*) para redeployar cuando se publique una imagen nueva.

## Notas

- El límite de memoria es 1 GB por servicio. El stack de Chatwoot de producción tiene 512 MB y se reinicia bajo carga.
- No reutilizar la base `chatwoot` ni sus credenciales.
