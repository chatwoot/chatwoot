# Start Chatwoot Script for Windows PowerShell
Write-Host "Starting Chatwoot containers..." -ForegroundColor Green

# Navigate to project directory
Set-Location "D:\Projects\Crove"

# Start containers
Write-Host "Starting Rails and Sidekiq containers..." -ForegroundColor Yellow
docker-compose up -d rails sidekiq

# Wait a moment for containers to start
Start-Sleep -Seconds 5

# Check container status
Write-Host "`nChecking container status:" -ForegroundColor Cyan
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | Select-String -Pattern "crove"

Write-Host "`nChatwoot should be accessible at: http://localhost:3007" -ForegroundColor Green
Write-Host "To view logs: docker-compose logs -f rails" -ForegroundColor Yellow 