# Check Chatwoot Status Script
Write-Host "=== CHATWOOT STATUS CHECK ===" -ForegroundColor Cyan

# Check if Docker is running
Write-Host "`n1. Checking Docker status..." -ForegroundColor Yellow
$dockerStatus = docker version 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✓ Docker is running" -ForegroundColor Green
} else {
    Write-Host "   ✗ Docker is NOT running! Please start Docker Desktop." -ForegroundColor Red
    exit 1
}

# Check containers
Write-Host "`n2. Checking containers..." -ForegroundColor Yellow
$containers = docker ps --format "{{.Names}}" | Select-String -Pattern "rails|vite|sidekiq"
if ($containers) {
    Write-Host "   ✓ Chatwoot containers found:" -ForegroundColor Green
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | Select-String -Pattern "rails|vite|sidekiq"
} else {
    Write-Host "   ✗ No Chatwoot containers running" -ForegroundColor Red
    Write-Host "   Run: .\start-chatwoot.ps1" -ForegroundColor Yellow
}

# Check PostgreSQL connection
Write-Host "`n3. Checking PostgreSQL..." -ForegroundColor Yellow
$pgContainer = docker ps --format "{{.Names}}" | Select-String -Pattern "DB"
if ($pgContainer) {
    Write-Host "   ✓ PostgreSQL container 'DB' is running" -ForegroundColor Green
} else {
    Write-Host "   ✗ PostgreSQL container 'DB' is NOT running" -ForegroundColor Red
}

# Check Redis
Write-Host "`n4. Checking Redis..." -ForegroundColor Yellow
$redisContainer = docker ps --format "{{.Names}}" | Select-String -Pattern "redis"
if ($redisContainer) {
    Write-Host "   ✓ Redis container is running" -ForegroundColor Green
} else {
    Write-Host "   ✗ Redis container is NOT running" -ForegroundColor Red
}

# Test localhost:3007
Write-Host "`n5. Testing http://localhost:3007..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3007" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "   ✓ Chatwoot is accessible!" -ForegroundColor Green
    }
} catch {
    Write-Host "   ✗ Cannot connect to localhost:3007" -ForegroundColor Red
    Write-Host "   Error: $_" -ForegroundColor Yellow
}

Write-Host "`n=== TROUBLESHOOTING TIPS ===" -ForegroundColor Cyan
Write-Host "1. If Docker is not running: Start Docker Desktop"
Write-Host "2. If containers are not running: Run .\start-chatwoot.ps1"
Write-Host "3. To view logs: docker-compose logs -f rails"
Write-Host "4. To restart everything: docker-compose restart rails sidekiq" 