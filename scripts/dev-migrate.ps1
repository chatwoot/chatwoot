$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

docker compose -f docker-compose.dokploy.yml -f docker-compose.dokploy.fork.yml exec chatwoot-rails bundle exec rails db:migrate
