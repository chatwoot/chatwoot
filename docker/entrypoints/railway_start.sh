#!/bin/sh
# CUSTOMIZAÇÃO_SYNAPSEOS
# Dispatcher do Railway: um único startCommand em railway.json serve todos os
# serviços. Seleciona o script real a partir de RAILWAY_SERVICE_NAME (injetado
# pelo Railway) — web default, worker quando o serviço se chama worker/sidekiq.
# O log explícito de entrada facilita diagnóstico no painel de logs.
set -e

echo "[railway_start] RAILWAY_SERVICE_NAME=${RAILWAY_SERVICE_NAME:-<unset>}"

case "${RAILWAY_SERVICE_NAME:-web}" in
  worker|sidekiq|*worker*|*sidekiq*)
    echo "[railway_start] dispatching -> railway_worker.sh"
    exec /app/docker/entrypoints/railway_worker.sh
    ;;
  *)
    echo "[railway_start] dispatching -> railway_web.sh"
    exec /app/docker/entrypoints/railway_web.sh
    ;;
esac
