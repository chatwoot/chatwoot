# Compila assets Vue y reinicia Rails (cambios frontend en fork local).
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

pnpm exec vite build
docker compose -f docker-compose.dokploy.yml -f docker-compose.dokploy.fork.yml restart chatwoot-rails
