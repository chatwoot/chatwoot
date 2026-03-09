param(
    [Parameter(Position=0)]
    [string]$BackupFile = "",
    [switch]$Force,
    [switch]$StartContainers,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

# Configuracoes
$ComposeFile = "docker-compose.yaml"
$ProjectName = "chatwit-dev"
$BackupFolder = "bkp"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  CHATWIT - RESTAURACAO DE BACKUP        " -ForegroundColor Cyan  
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Funcao para mostrar ajuda
function Show-Help {
    Write-Host "USO:" -ForegroundColor Green
    Write-Host "  .\restore-database.ps1 [ARQUIVO_BACKUP] [OPCOES]" -ForegroundColor White
    Write-Host ""
    Write-Host "PARAMETROS:" -ForegroundColor Green
    Write-Host "  ARQUIVO_BACKUP  - Caminho para o arquivo de backup (opcional)" -ForegroundColor White
    Write-Host "                   Se nao informado, usa o mais recente da pasta bkp/" -ForegroundColor White
    Write-Host ""
    Write-Host "OPCOES:" -ForegroundColor Green
    Write-Host "  -Force          - Forcar restauracao sem confirmacao" -ForegroundColor White
    Write-Host "  -StartContainers - Iniciar containers apos restauracao" -ForegroundColor White
    Write-Host "  -Help           - Mostrar esta ajuda" -ForegroundColor White
    Write-Host ""
    Write-Host "EXEMPLOS:" -ForegroundColor Green
    Write-Host "  .\restore-database.ps1                           # Restaurar backup mais recente" -ForegroundColor Cyan
    Write-Host "  .\restore-database.ps1 backup.sql.gz             # Restaurar arquivo especifico" -ForegroundColor Cyan
    Write-Host "  .\restore-database.ps1 -Force                    # Sem confirmacao" -ForegroundColor Cyan
    Write-Host "  .\restore-database.ps1 -StartContainers          # Iniciar ambiente apos" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "NOTA:" -ForegroundColor Yellow
    Write-Host "  O script automaticamente:" -ForegroundColor White
    Write-Host "  - Para containers existentes" -ForegroundColor White
    Write-Host "  - Inicia PostgreSQL" -ForegroundColor White
    Write-Host "  - Limpa banco atual" -ForegroundColor White
    Write-Host "  - Restaura backup" -ForegroundColor White
    Write-Host "  - Verifica integridade" -ForegroundColor White
}

# Verificar se e pedido de ajuda
if ($Help -or $BackupFile -eq "-h" -or $BackupFile -eq "--help") {
    Show-Help
    exit 0
}

# Preparar comandos docker-compose
$DockerComposeCmd = "docker-compose -f $ComposeFile -p $ProjectName"

# Funcao para encontrar o backup mais recente
function Get-LatestBackup {
    if (-not (Test-Path $BackupFolder)) {
        Write-Host "[ERROR] Pasta '$BackupFolder' nao encontrada!" -ForegroundColor Red
        exit 1
    }
    
    $backupFiles = Get-ChildItem -Path $BackupFolder -Filter "*.sql.gz" | Sort-Object LastWriteTime -Descending
    
    if ($backupFiles.Count -eq 0) {
        Write-Host "[ERROR] Nenhum arquivo .sql.gz encontrado na pasta '$BackupFolder'!" -ForegroundColor Red
        exit 1
    }
    
    $latestBackup = $backupFiles[0]
    Write-Host "[INFO] Backup mais recente encontrado: $($latestBackup.Name)" -ForegroundColor Cyan
    Write-Host "[INFO] Tamanho: $([math]::Round($latestBackup.Length / 1MB, 2)) MB" -ForegroundColor Cyan
    Write-Host "[INFO] Data: $($latestBackup.LastWriteTime)" -ForegroundColor Cyan
    
    return $latestBackup.FullName
}

# Funcao para verificar se containers estao rodando
function Test-ContainersRunning {
    $containers = docker-compose -f $ComposeFile -p $ProjectName ps -q
    return $containers.Count -gt 0
}

# Funcao para parar containers
function Stop-Containers {
    Write-Host "[STOP] Parando containers existentes..." -ForegroundColor Yellow
    Invoke-Expression "$DockerComposeCmd down" | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SUCCESS] Containers parados!" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] Erro ao parar containers (pode ser normal se nao estavam rodando)" -ForegroundColor Yellow
    }
}

# Funcao para iniciar PostgreSQL
function Start-PostgreSQL {
    Write-Host "[POSTGRES] Iniciando PostgreSQL..." -ForegroundColor Green
    Invoke-Expression "$DockerComposeCmd up postgres -d" | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SUCCESS] PostgreSQL iniciado!" -ForegroundColor Green
        
        # Aguardar PostgreSQL ficar pronto
        Write-Host "[WAIT] Aguardando PostgreSQL ficar pronto..." -ForegroundColor Cyan
        Start-Sleep -Seconds 5
        
        # Testar conexao
        $maxAttempts = 10
        $attempt = 0
        
        do {
            $attempt++
            Write-Host "[TEST] Testando conexao PostgreSQL (tentativa $attempt/$maxAttempts)..." -ForegroundColor Cyan
            
            $testResult = Invoke-Expression "$DockerComposeCmd exec postgres pg_isready -U postgres" 2>$null
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[SUCCESS] PostgreSQL pronto!" -ForegroundColor Green
                return $true
            }
            
            if ($attempt -lt $maxAttempts) {
                Write-Host "[WAIT] Aguardando mais 3 segundos..." -ForegroundColor Yellow
                Start-Sleep -Seconds 3
            }
        } while ($attempt -lt $maxAttempts)
        
        Write-Host "[ERROR] PostgreSQL nao ficou pronto apos $maxAttempts tentativas!" -ForegroundColor Red
        return $false
    } else {
        Write-Host "[ERROR] Falha ao iniciar PostgreSQL!" -ForegroundColor Red
        return $false
    }
}

# Funcao para limpar banco
function Clear-Database {
    Write-Host "[DB] Limpando banco de dados..." -ForegroundColor Yellow
    
    # Remover banco se existir
    Write-Host "[DB] Removendo banco 'chatwoot' se existir..." -ForegroundColor Cyan
    Invoke-Expression "$DockerComposeCmd exec postgres psql -U postgres -c 'DROP DATABASE IF EXISTS chatwoot;'" | Out-Null
    
    # Criar banco novo
    Write-Host "[DB] Criando banco 'chatwoot'..." -ForegroundColor Cyan
    Invoke-Expression "$DockerComposeCmd exec postgres psql -U postgres -c 'CREATE DATABASE chatwoot;'" | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SUCCESS] Banco limpo e criado!" -ForegroundColor Green
        return $true
    } else {
        Write-Host "[ERROR] Falha ao limpar/criar banco!" -ForegroundColor Red
        return $false
    }
}

# Funcao para restaurar backup
function Restore-Backup {
    param([string]$BackupPath)
    
    Write-Host "[RESTORE] Restaurando backup..." -ForegroundColor Green
    Write-Host "[INFO] Arquivo: $BackupPath" -ForegroundColor Cyan
    
    # Copiar arquivo para container
    $fileName = Split-Path $BackupPath -Leaf
    Write-Host "[COPY] Copiando arquivo para container..." -ForegroundColor Cyan
    Invoke-Expression "docker cp '$BackupPath' chatwit-dev-postgres-1:/tmp/$fileName" | Out-Null
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Falha ao copiar arquivo para container!" -ForegroundColor Red
        return $false
    }
    
    # Restaurar backup
    Write-Host "[RESTORE] Executando restauracao..." -ForegroundColor Cyan
    $restoreCmd = "$DockerComposeCmd exec postgres bash -c 'gunzip -c /tmp/$fileName | psql -U postgres -d chatwoot'"
    Invoke-Expression $restoreCmd
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SUCCESS] Backup restaurado com sucesso!" -ForegroundColor Green
        
        # Limpar arquivo temporario
        Invoke-Expression "$DockerComposeCmd exec postgres rm -f /tmp/$fileName" | Out-Null
        
        return $true
    } else {
        Write-Host "[ERROR] Falha ao restaurar backup!" -ForegroundColor Red
        return $false
    }
}

# Funcao para verificar integridade
function Test-DatabaseIntegrity {
    Write-Host "[VERIFY] Verificando integridade do banco..." -ForegroundColor Green
    
    $checks = @(
        @{Name="Contas"; Query="SELECT COUNT(*) FROM accounts;"},
        @{Name="Conversas"; Query="SELECT COUNT(*) FROM conversations;"},
        @{Name="Mensagens"; Query="SELECT COUNT(*) FROM messages;"},
        @{Name="Usuarios"; Query="SELECT COUNT(*) FROM users;"},
        @{Name="Inboxes"; Query="SELECT COUNT(*) FROM inboxes;"}
    )
    
    $results = @{}
    
    foreach ($check in $checks) {
        try {
            $result = Invoke-Expression "$DockerComposeCmd exec postgres psql -U postgres -d chatwoot -t -c '$($check.Query)'" 2>$null
            $count = ($result | Out-String -Width 1000).Trim()
            $count = ($count -replace '\s+', '').Trim()
            
            if ($count -match '^\d+$') {
                $results[$check.Name] = [int]$count
                Write-Host "[VERIFY] $($check.Name): $count" -ForegroundColor Green
            } else {
                Write-Host "[ERROR] Falha ao verificar $($check.Name) - resultado: '$count'" -ForegroundColor Red
                return $false
            }
        } catch {
            Write-Host "[ERROR] Erro ao verificar $($check.Name): $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    }
    
    # Verificar se tem dados minimos
    if ($results["Contas"] -eq 0) {
        Write-Host "[WARNING] Nenhuma conta encontrada no backup!" -ForegroundColor Yellow
    }
    
    if ($results["Conversas"] -eq 0) {
        Write-Host "[WARNING] Nenhuma conversa encontrada no backup!" -ForegroundColor Yellow
    }
    
    Write-Host "[SUCCESS] Verificacao de integridade concluida!" -ForegroundColor Green
    return $true
}

# Funcao para iniciar ambiente completo
function Start-FullEnvironment {
    Write-Host "[START] Iniciando ambiente completo..." -ForegroundColor Green
    Write-Host "[INFO] Executando build-desenvolvimento.ps1 up..." -ForegroundColor Cyan
    
    Invoke-Expression ".\build-desenvolvimento.ps1 up"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SUCCESS] Ambiente iniciado com sucesso!" -ForegroundColor Green
        Write-Host ""
        Write-Host "SERVICOS DISPONIVEIS:" -ForegroundColor Cyan
        Write-Host "  Chatwit (Rails):     http://localhost:3000" -ForegroundColor White
        Write-Host "  Vite Dev Server:     http://localhost:3036" -ForegroundColor White  
        Write-Host "  MailHog:             http://localhost:8025" -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host "[ERROR] Falha ao iniciar ambiente!" -ForegroundColor Red
    }
}

# ===== EXECUCAO PRINCIPAL =====

try {
    # Determinar arquivo de backup
    if ([string]::IsNullOrEmpty($BackupFile)) {
        Write-Host "[INFO] Nenhum arquivo especificado, procurando backup mais recente..." -ForegroundColor Cyan
        $BackupFile = Get-LatestBackup
    } else {
        # Verificar se arquivo existe
        if (-not (Test-Path $BackupFile)) {
            # Tentar na pasta bkp
            $bkpPath = Join-Path $BackupFolder $BackupFile
            if (Test-Path $bkpPath) {
                $BackupFile = $bkpPath
            } else {
                Write-Host "[ERROR] Arquivo de backup nao encontrado: $BackupFile" -ForegroundColor Red
                exit 1
            }
        }
        
        Write-Host "[INFO] Usando arquivo especificado: $BackupFile" -ForegroundColor Cyan
    }
    
    # Confirmacao (se nao for forçado)
    if (-not $Force) {
        Write-Host ""
        Write-Host "[WARNING] Esta operacao ira:" -ForegroundColor Yellow
        Write-Host "  - Parar containers existentes" -ForegroundColor White
        Write-Host "  - Limpar banco de dados atual" -ForegroundColor White
        Write-Host "  - Restaurar backup: $BackupFile" -ForegroundColor White
        Write-Host ""
        Write-Host "Continuar? (y/N): " -ForegroundColor Red -NoNewline
        $confirm = Read-Host
        
        if ($confirm -ne "y" -and $confirm -ne "Y") {
            Write-Host "[CANCELLED] Operacao cancelada pelo usuario." -ForegroundColor Yellow
            exit 0
        }
    }
    
    Write-Host ""
    Write-Host "[START] Iniciando processo de restauracao..." -ForegroundColor Green
    
    # 1. Parar containers se estiverem rodando
    if (Test-ContainersRunning) {
        Stop-Containers
    }
    
    # 2. Iniciar PostgreSQL
    if (-not (Start-PostgreSQL)) {
        Write-Host "[ERROR] Falha ao iniciar PostgreSQL!" -ForegroundColor Red
        exit 1
    }
    
    # 3. Limpar banco
    if (-not (Clear-Database)) {
        Write-Host "[ERROR] Falha ao limpar banco!" -ForegroundColor Red
        exit 1
    }
    
    # 4. Restaurar backup
    if (-not (Restore-Backup -BackupPath $BackupFile)) {
        Write-Host "[ERROR] Falha ao restaurar backup!" -ForegroundColor Red
        exit 1
    }
    
    # 5. Verificar integridade
    if (-not (Test-DatabaseIntegrity)) {
        Write-Host "[ERROR] Falha na verificacao de integridade!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "  RESTAURACAO CONCLUIDA COM SUCESSO!     " -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host ""
    
    # 6. Iniciar ambiente completo se solicitado
    if ($StartContainers) {
        Write-Host ""
        Start-FullEnvironment
    } else {
        Write-Host "[INFO] Para iniciar o ambiente completo, execute:" -ForegroundColor Cyan
        Write-Host "  .\build-desenvolvimento.ps1 up" -ForegroundColor White
        Write-Host ""
        Write-Host "[INFO] Ou use a opcao -StartContainers para iniciar automaticamente" -ForegroundColor Cyan
    }
    
} catch {
    Write-Host "[ERROR] Erro inesperado: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
