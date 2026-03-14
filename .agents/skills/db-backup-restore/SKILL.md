---
name: db-backup-restore
description: "Backup a production PostgreSQL database and restore it to a local Docker dev environment. Use this skill whenever the user asks to: dump production, backup the database, restore prod to dev, refresh dev database, pull production data, sync prod to local, pg_dump, pg_restore, or mentions 'bkp do banco', 'restaurar banco', 'dump produção', 'copiar banco'. Also trigger when the user mentions refreshing local data from a remote server, even if they don't say 'backup' explicitly."
---

# Database Backup & Restore (Production → Dev)

Dumps a PostgreSQL database from a remote production server (via SSH + Docker) and restores it into a local Docker Compose PostgreSQL instance. Agnostic to the specific project — works with any Dockerized Postgres setup.

## Prerequisites

- SSH access to the production server with a key file
- Production database running inside a Docker container (or Swarm service)
- Local dev environment using Docker Compose with a Postgres service

## Key Paths (WitDev Ecosystem)

| Item | Path / Value |
|------|-------------|
| SSH key (global) | `~/.ssh/keys/production-server.key` |
| SSH key (legacy) | `~/Chatwit-Social-dev/id_rsa.v3` |
| Production server | `root@49.13.155.94` |
| Prod container filter | `name=postgres_postgres` |
| Prod database name | `chatwoot` |
| Local compose file | `docker-compose.dev.yaml` |
| Local container | `chatwit-postgres-1` |
| Local database name | `chatwoot` |
| Local Postgres port | `5434` (mapped to 5432) |
| Local Postgres user | `postgres` |

Adapt these values for other projects. The workflow is the same regardless of names.

## Workflow

### Step 1 — Identify production database

SSH into the server and list databases to confirm the correct name:

```bash
SSH_KEY=~/.ssh/keys/production-server.key
PROD_HOST=root@49.13.155.94
CONTAINER_FILTER=name=postgres_postgres

ssh -i "$SSH_KEY" "$PROD_HOST" \
  "docker exec \$(docker ps -q -f $CONTAINER_FILTER) psql -U postgres -lqt" \
  | cut -d'|' -f1 | sed 's/ //g' | grep -v '^$'
```

Ask the user which database to dump if multiple exist and it's ambiguous.

### Step 2 — Dump production database

Create a custom-format dump (`-Fc`) which is compressed and supports selective restore:

```bash
PROD_DB=chatwoot

ssh -i "$SSH_KEY" "$PROD_HOST" \
  "docker exec \$(docker ps -q -f $CONTAINER_FILTER) pg_dump -U postgres -Fc $PROD_DB" \
  > "${PROD_DB}_prod_backup.dump"
```

Verify the dump file is non-empty:

```bash
ls -lh "${PROD_DB}_prod_backup.dump"
```

If the file is 0 bytes or very small (< 1KB), something went wrong — check SSH connectivity and container name.

### Step 3 — Prepare local database

Ensure the local Postgres container is running:

```bash
docker compose -f docker-compose.dev.yaml ps postgres
```

If it's not running, start it:

```bash
docker compose -f docker-compose.dev.yaml up -d postgres
```

Terminate existing connections, then drop and recreate the database:

```bash
LOCAL_CONTAINER=chatwit-postgres-1
LOCAL_DB=chatwoot
PG_USER=postgres

docker exec "$LOCAL_CONTAINER" psql -U "$PG_USER" -c \
  "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='$LOCAL_DB' AND pid <> pg_backend_pid();"

docker exec "$LOCAL_CONTAINER" psql -U "$PG_USER" -c "DROP DATABASE IF EXISTS $LOCAL_DB;"
docker exec "$LOCAL_CONTAINER" psql -U "$PG_USER" -c "CREATE DATABASE $LOCAL_DB;"
```

### Step 4 — Restore

Copy the dump into the container and restore:

```bash
docker cp "${PROD_DB}_prod_backup.dump" "$LOCAL_CONTAINER:/tmp/backup.dump"

docker exec "$LOCAL_CONTAINER" pg_restore \
  -U "$PG_USER" -d "$LOCAL_DB" \
  --no-owner --no-privileges \
  /tmp/backup.dump
```

`--no-owner` and `--no-privileges` prevent errors when local user/roles differ from production.

Some warnings about missing roles are normal and harmless.

### Step 5 — Verify

Run a quick sanity check on the restored data:

```bash
docker exec "$LOCAL_CONTAINER" psql -U "$PG_USER" -d "$LOCAL_DB" -c \
  "SELECT count(*) AS tables FROM information_schema.tables
   WHERE table_schema='public' AND table_type='BASE TABLE';"
```

For Chatwoot specifically, also check key counts:

```bash
docker exec "$LOCAL_CONTAINER" psql -U "$PG_USER" -d "$LOCAL_DB" -c \
  "SELECT
     (SELECT count(*) FROM accounts) AS accounts,
     (SELECT count(*) FROM contacts) AS contacts,
     (SELECT count(*) FROM conversations) AS conversations,
     (SELECT count(*) FROM messages) AS messages;"
```

For other projects, adapt the verification query to check the most important tables.

### Step 6 — Cleanup

The dump file stays in the project directory. Inform the user they can delete it:

```bash
rm "${PROD_DB}_prod_backup.dump"
```

Also clean up inside the container:

```bash
docker exec "$LOCAL_CONTAINER" rm -f /tmp/backup.dump
```

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| `PG::ConnectionBad` | Running psql outside Docker | Use `docker exec` to run inside the container |
| Empty dump file (0 bytes) | Wrong container name or SSH key | Verify with `docker ps` on remote, check key path |
| `database does not exist` | Wrong database name | List databases first (Step 1) |
| `role "xxx" does not exist` warnings | Production roles don't exist locally | Safe to ignore — `--no-owner` handles this |
| Restore errors on extensions | Missing extensions in local image | Ensure local image matches (e.g., `pgvector/pgvector:pg17`) |
| Volume incompatible after PG upgrade | Old volume has previous PG data format | Stop container, `docker volume rm <volume>`, start fresh, then restore |

## Adapting to Other Projects

Replace these variables for any project:

```bash
SSH_KEY=~/.ssh/keys/<your-key>
PROD_HOST=<user>@<host>
CONTAINER_FILTER=name=<prod-postgres-container>
PROD_DB=<database-name>
LOCAL_CONTAINER=<local-container-name>
LOCAL_DB=<local-database-name>
PG_USER=<postgres-user>
```

The 6-step workflow (identify → dump → prepare → restore → verify → cleanup) stays exactly the same.
