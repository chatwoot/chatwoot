# Compila assets Vue y monta public/vite en Rails (fork local).
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

pnpm exec vite build
docker compose -f docker-compose.dokploy.yml -f docker-compose.dokploy.fork.yml -f docker-compose.vite-local.yml up -d --force-recreate chatwoot-rails chatwoot-sidekiq
