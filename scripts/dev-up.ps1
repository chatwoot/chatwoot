# Levanta Chatwoot fork LOCAL (build desde disco, no GHCR).
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

$network = "main-chatwoot-local"
$exists = docker network ls --format "{{.Name}}" | Select-String -Pattern "^$network$"
if (-not $exists) {
  Write-Host "Creating network $network..."
  docker network create $network
}

Write-Host "Building and starting inboxhub-chatwoot:local..."

# Windows: entrypoints must be LF or Rails container crash-loops
Get-ChildItem "$PSScriptRoot\..\docker\entrypoints" -Recurse -Include *.sh,*.rb | ForEach-Object {
  $t = [IO.File]::ReadAllText($_.FullName) -replace "`r`n", "`n" -replace "`r", "`n"
  [IO.File]::WriteAllText($_.FullName, $t, [Text.UTF8Encoding]::new($false))
}

docker compose -f docker-compose.dokploy.yml -f docker-compose.dokploy.fork.yml up -d --build
if ($LASTEXITCODE -ne 0) { Write-Error "Docker build failed."; exit 1 }

Write-Host "Waiting for Rails to boot..."
Start-Sleep -Seconds 60

Write-Host "Running pending migrations..."
docker compose -f docker-compose.dokploy.yml -f docker-compose.dokploy.fork.yml exec -T chatwoot-rails bundle exec rails db:migrate
if ($LASTEXITCODE -ne 0) {
  Write-Error "Migration failed. Is chatwoot-rails running?"
  exit 1
}

Write-Host ""
Write-Host "Ready:"
Write-Host "  Chatwoot:  http://localhost:3000"
Write-Host "  Widget:    http://localhost:8080/test-chat.html"
docker ps --filter "name=chatwoot" --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
