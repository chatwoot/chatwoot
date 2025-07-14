# Chatwoot Health Monitor Script
param(
    [int]$CheckInterval = 30,  # seconds between checks
    [int]$Timeout = 15         # seconds before considering it frozen
)

Write-Host "=== CHATWOOT HEALTH MONITOR ===" -ForegroundColor Cyan
Write-Host "Checking every $CheckInterval seconds..." -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray

$freezeCount = 0
$lastResponseTime = 0

while ($true) {
    Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] Checking..." -NoNewline
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3007/api/v1/accounts/2/cache_keys" `
            -UseBasicParsing -TimeoutSec $Timeout -ErrorAction Stop
        
        $stopwatch.Stop()
        $responseTime = [math]::Round($stopwatch.Elapsed.TotalSeconds, 2)
        
        if ($response.StatusCode -eq 200) {
            Write-Host " ✓ OK ($responseTime s)" -ForegroundColor Green
            $freezeCount = 0
        }
    }
    catch {
        $stopwatch.Stop()
        Write-Host " ✗ TIMEOUT/ERROR" -ForegroundColor Red
        $freezeCount++
        
        if ($freezeCount -ge 2) {
            Write-Host "`n⚠️  CHATWOOT APPEARS FROZEN!" -ForegroundColor Red
            Write-Host "Attempting auto-recovery..." -ForegroundColor Yellow
            
            # Restart Rails container
            docker restart rails
            Write-Host "Rails container restarted. Waiting 30s..." -ForegroundColor Yellow
            Start-Sleep -Seconds 30
            $freezeCount = 0
        }
    }
    
    # Show container stats
    if ($freezeCount -eq 0) {
        $stats = docker stats rails --no-stream --format "CPU: {{.CPUPerc}} | MEM: {{.MemUsage}}"
        Write-Host "   $stats" -ForegroundColor Gray
    }
    
    Start-Sleep -Seconds $CheckInterval
} 