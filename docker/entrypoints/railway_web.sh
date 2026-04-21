#!/bin/sh
# CUSTOMIZAÇÃO_SYNAPSEOS
# Entrypoint do serviço web no Railway.
#
# Responsabilidades:
# 1. Traduz variáveis do Railway (DATABASE_URL, REDIS_URL) para o formato que o
#    Chatwoot espera (POSTGRES_HOST/USER/PASS/DB_NAME e REDIS_URL).
# 2. Prepara o banco na primeira execução (db:chatwoot_prepare é idempotente).
# 3. Inicia o Puma bindado em 0.0.0.0:$PORT (porta que o Railway atribui).
set -e

# --- Parse DATABASE_URL into POSTGRES_* vars if provided ---------------------
# DATABASE_URL vem no formato: postgresql://user:pass@host:port/database
if [ -n "$DATABASE_URL" ] && [ -z "$POSTGRES_HOST" ]; then
  # Extrai com shell puro (evita dependência de Ruby só pra parse).
  proto_removed="${DATABASE_URL#*://}"
  creds_host="${proto_removed%%/*}"
  path="${proto_removed#*/}"
  creds="${creds_host%@*}"
  host_port="${creds_host#*@}"
  export POSTGRES_USERNAME="${creds%%:*}"
  export POSTGRES_PASSWORD="${creds#*:}"
  export POSTGRES_HOST="${host_port%%:*}"
  export POSTGRES_PORT="${host_port#*:}"
  export POSTGRES_DATABASE="${path%%\?*}"
fi

# --- Health wait: espera Postgres responder ---------------------------------
echo "[railway_web] waiting for postgres $POSTGRES_HOST:$POSTGRES_PORT..."
for i in $(seq 1 60); do
  if pg_isready -h "$POSTGRES_HOST" -p "${POSTGRES_PORT:-5432}" -U "$POSTGRES_USERNAME" >/dev/null 2>&1; then
    echo "[railway_web] postgres ready"
    break
  fi
  sleep 2
done

# --- Prepare DB (idempotente: cria se faltar, migra sempre) -----------------
echo "[railway_web] running db:chatwoot_prepare"
bundle exec rake db:chatwoot_prepare || {
  echo "[railway_web] db:chatwoot_prepare failed, falling back to db:migrate"
  bundle exec rails db:migrate
}

# --- Start Puma -------------------------------------------------------------
PORT="${PORT:-3000}"
echo "[railway_web] starting puma on 0.0.0.0:$PORT"
exec bundle exec rails server -b 0.0.0.0 -p "$PORT"
