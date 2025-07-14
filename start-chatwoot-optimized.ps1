# Optimized Chatwoot Startup Script
Write-Host "=== STARTING OPTIMIZED CHATWOOT ===" -ForegroundColor Cyan

# Check Docker
$dockerStatus = docker version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker is not running! Please start Docker Desktop." -ForegroundColor Red
    exit 1
}

Write-Host "1. Setting up environment variables..." -ForegroundColor Yellow
$env:RAILS_ENV = "development"
$env:RAILS_MAX_THREADS = "10"
$env:WEB_CONCURRENCY = "2"
$env:MALLOC_ARENA_MAX = "2"
$env:RAILS_LOG_TO_STDOUT = "true"
$env:RAILS_LOG_LEVEL = "warn"

Write-Host "2. Cleaning up old processes..." -ForegroundColor Yellow
docker-compose down
Start-Sleep -Seconds 2

Write-Host "3. Starting services with optimized settings..." -ForegroundColor Yellow
docker-compose up -d postgres redis

Write-Host "4. Waiting for database..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

Write-Host "5. Starting Rails with performance flags..." -ForegroundColor Yellow
docker-compose run --rm -e RAILS_ENV=development -e DISABLE_SPRING=1 rails bundle exec rails db:prepare
docker-compose up -d rails sidekiq vite

Write-Host "6. Enabling Rails cache..." -ForegroundColor Yellow
Start-Sleep -Seconds 10
docker exec rails bundle exec rails dev:cache

Write-Host "7. Precompiling assets..." -ForegroundColor Yellow
docker exec rails bundle exec rails assets:precompile

Write-Host "`n=== OPTIMIZATION COMPLETE ===" -ForegroundColor Green
Write-Host "Chatwoot should be faster now!"
Write-Host "Access at: http://localhost:3007"
Write-Host "`nTips:" -ForegroundColor Cyan
Write-Host "- First load will still take 20-30 seconds"
Write-Host "- Subsequent loads should be faster"
Write-Host "- Monitor logs: docker-compose logs -f rails" 