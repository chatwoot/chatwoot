#!/bin/sh
# CUSTOMIZAÇÃO_SYNAPSEOS
# Dispatcher do Railway: um único startCommand em railway.json serve todos os
# serviços. Seleciona o script real a partir de RAILWAY_SERVICE_NAME (injetado
# pelo Railway) — web default, worker quando o serviço se chama worker/sidekiq.
set -e

case "${RAILWAY_SERVICE_NAME:-web}" in
  worker|sidekiq)
    exec /app/docker/entrypoints/railway_worker.sh
    ;;
  *)
    exec /app/docker/entrypoints/railway_web.sh
    ;;
esac
