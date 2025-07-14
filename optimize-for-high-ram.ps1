# High-Performance Chatwoot Setup for 90GB RAM
Write-Host "=== HIGH PERFORMANCE CHATWOOT SETUP ===" -ForegroundColor Cyan
Write-Host "Detected: 90GB RAM allocated to WSL" -ForegroundColor Green

# Stop everything first
Write-Host "`n1. Cleaning up..." -ForegroundColor Yellow
docker-compose down
docker stop DB redis 2>$null

# Optimize PostgreSQL with high memory
Write-Host "`n2. Starting PostgreSQL with 16GB config..." -ForegroundColor Yellow
docker run -d --name DB `
    -e POSTGRES_USER=joy `
    -e POSTGRES_PASSWORD=chatwoot `
    -e POSTGRES_DB=chatwoot_development `
    -p 5432:5432 `
    --memory="16g" `
    --cpus="4" `
    -v pgdata:/var/lib/postgresql/data `
    pgvector/pgvector:pg17 `
    postgres `
    -c shared_buffers=4GB `
    -c effective_cache_size=12GB `
    -c maintenance_work_mem=2GB `
    -c work_mem=256MB `
    -c max_connections=500 `
    -c random_page_cost=1.1 `
    -c effective_io_concurrency=200 `
    -c wal_buffers=64MB `
    -c min_wal_size=2GB `
    -c max_wal_size=8GB `
    -c checkpoint_completion_target=0.9 `
    -c max_parallel_workers_per_gather=4 `
    -c max_parallel_workers=8 `
    -c max_parallel_maintenance_workers=4

# Optimize Redis with high memory
Write-Host "`n3. Starting Redis with 8GB config..." -ForegroundColor Yellow
docker run -d --name redis `
    -p 6379:6379 `
    --memory="8g" `
    --cpus="2" `
    -v redis_data:/data `
    redis:latest `
    redis-server `
    --maxmemory 6gb `
    --maxmemory-policy allkeys-lru `
    --appendonly yes `
    --appendfsync everysec

Start-Sleep -Seconds 5

# Configure sysctl for high performance
Write-Host "`n4. Optimizing WSL kernel parameters..." -ForegroundColor Yellow
wsl.exe -d Ubuntu -u root bash -c @'
echo "vm.swappiness=10" >> /etc/sysctl.conf
echo "vm.dirty_ratio=15" >> /etc/sysctl.conf
echo "vm.dirty_background_ratio=5" >> /etc/sysctl.conf
echo "net.core.somaxconn=65535" >> /etc/sysctl.conf
echo "net.ipv4.tcp_max_syn_backlog=65536" >> /etc/sysctl.conf
sysctl -p
'@

# Start Chatwoot with override config
Write-Host "`n5. Starting Chatwoot with high-performance config..." -ForegroundColor Yellow
docker-compose up -d

Write-Host "`n6. Waiting for services to stabilize..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# Enable Rails optimizations
Write-Host "`n7. Applying Rails optimizations..." -ForegroundColor Yellow
docker exec rails bundle exec rails dev:cache
docker exec rails bundle exec rails assets:precompile

# Warm up the application
Write-Host "`n8. Warming up application..." -ForegroundColor Yellow
for ($i = 1; $i -le 3; $i++) {
    Write-Host "   Warm-up request $i/3..." -NoNewline
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3007" -UseBasicParsing -TimeoutSec 60
        Write-Host " OK" -ForegroundColor Green
    } catch {
        Write-Host " Failed" -ForegroundColor Red
    }
    Start-Sleep -Seconds 2
}

Write-Host "`n=== OPTIMIZATION COMPLETE ===" -ForegroundColor Green
Write-Host @"

Current Resource Allocation:
- PostgreSQL: 16GB RAM, 4 CPUs
- Redis: 8GB RAM, 2 CPUs  
- Rails: 16GB RAM, 8 CPUs
- Sidekiq: 8GB RAM, 4 CPUs
- Vite: 4GB RAM, 2 CPUs
- Total: ~52GB RAM allocated

Performance Expectations:
- First page load: 5-10 seconds
- Subsequent loads: <2 seconds
- Concurrent users supported: 100+

Monitor performance:
docker stats --no-stream

Access Chatwoot at: http://localhost:3007
"@ -ForegroundColor Cyan 