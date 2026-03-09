param(
    [Parameter(Position=0)]
    [string]$Action = "up",
    [switch]$Build,
    [switch]$Detach,
    [switch]$Force,
    [switch]$Logs
)

$ErrorActionPreference = "Stop"

# Configurações
$ComposeFile = "docker-compose-ngrok.yaml"
$ProjectName = "chatwit-dev"
$NgrokAuthToken = "31A71USAsfWBPiCJZc9Dw39a35k_2fUqtFQChZSDBMvwS1bxw"
$NgrokUrl = "beagle-great-awfully.ngrok-free.app"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  CHATWIT - DESENVOLVIMENTO COM NGROK    " -ForegroundColor Cyan  
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se o ngrok está rodando como serviço Docker
function Get-NgrokStatus {
    try {
        $ngrokContainer = Invoke-Expression "$DockerComposeCmd ps ngrok -q" 2>$null
        if ($ngrokContainer) {
            $containerStatus = docker inspect $ngrokContainer --format '{{.State.Status}}' 2>$null
            return $containerStatus -eq "running"
        }
        return $false
    } catch {
        return $false
    }
}

# Verificar se o arquivo .env.ngrok existe
if (-not (Test-Path ".env.ngrok")) {
    Write-Host "[WARNING] Arquivo .env.ngrok não encontrado!" -ForegroundColor Yellow
    if (Test-Path ".env.example") {
        Write-Host "[INFO] Copiando .env.example para .env.ngrok..." -ForegroundColor Cyan
        Copy-Item ".env.example" ".env.ngrok"
        Write-Host "[SUCCESS] Arquivo .env.ngrok criado! Configure as variáveis antes de continuar." -ForegroundColor Green
        Write-Host "[INFO] Editando .env.ngrok..." -ForegroundColor Cyan
        notepad .env.ngrok
        Write-Host "[INFO] Pressione Enter após configurar o .env.ngrok..." -ForegroundColor Yellow
        Read-Host
    } else {
        Write-Host "[ERROR] Arquivo .env.example não encontrado!" -ForegroundColor Red
        exit 1
    }
}

# Função para mostrar ajuda
function Show-Help {
    Write-Host "USO:" -ForegroundColor Green
    Write-Host "  .\build-desenvolvimento-ngrok.ps1 [ACAO] [OPCOES]" -ForegroundColor White
    Write-Host ""
    Write-Host "ACOES:" -ForegroundColor Green
    Write-Host "  up          - Subir todos os serviços com ngrok (padrão)" -ForegroundColor White
    Write-Host "  down        - Parar todos os serviços e ngrok" -ForegroundColor White
    Write-Host "  restart     - Reiniciar todos os serviços" -ForegroundColor White
    Write-Host "  logs        - Mostrar logs dos serviços" -ForegroundColor White
    Write-Host "  status      - Mostrar status dos containers" -ForegroundColor White
    Write-Host "  shell       - Entrar no container Rails" -ForegroundColor White
    Write-Host "  migrate     - Executar migrações pendentes" -ForegroundColor White
    Write-Host "  db-setup    - Configurar banco de dados" -ForegroundColor White
    Write-Host "  db-reset    - Resetar banco de dados" -ForegroundColor White
    Write-Host "  clean       - Limpar containers e volumes" -ForegroundColor White
    Write-Host ""
    Write-Host "OPCOES:" -ForegroundColor Green
    Write-Host "  -Build      - Rebuild imagens (só primeira vez ou mudanças em deps)" -ForegroundColor White
    Write-Host "  -Detach     - Executar em background" -ForegroundColor White
    Write-Host "  -Force      - Forçar operação (para clean)" -ForegroundColor White
    Write-Host "  -Logs       - Mostrar logs após subir" -ForegroundColor White
    Write-Host ""
    Write-Host "EXEMPLOS:" -ForegroundColor Green
    Write-Host "  .\build-desenvolvimento-ngrok.ps1 up -Build   # Primeira vez (setup completo)" -ForegroundColor Cyan
    Write-Host "  .\build-desenvolvimento-ngrok.ps1 up          # Uso diário (hot reload)" -ForegroundColor Cyan
    Write-Host "  .\build-desenvolvimento-ngrok.ps1 down        # Parar tudo" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "NGROK:" -ForegroundColor Yellow
    Write-Host "  URL externa: https://$NgrokUrl" -ForegroundColor White
    Write-Host "  Túnel expõe porta 3000 através do ngrok" -ForegroundColor White
    Write-Host "  Interface web: http://localhost:4040" -ForegroundColor White
    Write-Host ""
    Write-Host "NOTA:" -ForegroundColor Yellow
    Write-Host "  Usa ngrok como serviço Docker (não precisa instalar)" -ForegroundColor White
    Write-Host "  Hot reload ativo! Mudanças aparecem automaticamente" -ForegroundColor White
}

# Verificar se é pedido de ajuda
if ($Action -eq "help" -or $Action -eq "-h" -or $Action -eq "--help") {
    Show-Help
    exit 0
}

# Preparar comandos docker-compose
$DockerComposeCmd = "docker-compose -f $ComposeFile -p $ProjectName --env-file .env.ngrok"

Write-Host "[INFO] Projeto: $ProjectName" -ForegroundColor Cyan
Write-Host "[INFO] Arquivo: $ComposeFile" -ForegroundColor Cyan
Write-Host "[INFO] Ação: $Action" -ForegroundColor Cyan
Write-Host "[INFO] Ngrok URL: https://$NgrokUrl" -ForegroundColor Cyan
Write-Host ""

switch ($Action.ToLower()) {
    "up" {
        if ($Build) {
            Write-Host "[BUILD] Subindo ambiente com rebuild (primeira vez ou após mudanças em dependências)..." -ForegroundColor Green
        } else {
            Write-Host "[UP] Subindo ambiente de desenvolvimento (hot reload ativo)..." -ForegroundColor Green
            Write-Host "[INFO] Hot reload ativo! Mudanças no código aparecem automaticamente." -ForegroundColor Cyan
        }
        
        Write-Host "[NGROK] Incluindo ngrok como serviço Docker..." -ForegroundColor Cyan
        
        $cmd = "$DockerComposeCmd up"
        if ($Build) { $cmd += " --build" }
        if ($Detach) { $cmd += " -d" }
        
        Write-Host "[EXEC] $cmd" -ForegroundColor Yellow
        Invoke-Expression $cmd
        
        if ($LASTEXITCODE -eq 0) {
            # Aguardar ngrok inicializar
            Write-Host "[NGROK] Aguardando ngrok inicializar..." -ForegroundColor Cyan
            Start-Sleep -Seconds 5
            
            # Se foi build, executar setup inicial do banco
            if ($Build) {
                Write-Host ""
                Write-Host "[SETUP] Configurando ambiente inicial (primeira vez)..." -ForegroundColor Green
                
                Write-Host "[DB] Executando chatwoot_prepare..." -ForegroundColor Cyan
                Invoke-Expression "$DockerComposeCmd exec rails bundle exec rails db:chatwoot_prepare"
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "[DB] Executando seeds de desenvolvimento..." -ForegroundColor Cyan
                    Invoke-Expression "$DockerComposeCmd exec rails bundle exec rails db:seed"
                    
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host ""
                        Write-Host "[ENTERPRISE] Habilitando features Enterprise..." -ForegroundColor Cyan
                        $enterpriseScript = @"
puts 'Habilitando Enterprise...'
account = Account.first
enterprise_features = ['disable_branding', 'audit_logs', 'response_bot', 'sla', 'captain_integration', 'custom_roles']
account.enable_features(*enterprise_features)
InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN').update!(value: 'enterprise')
InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN_QUANTITY').update!(value: '999')
puts 'Enterprise habilitado com sucesso!'
"@
                        $enterpriseScript | Out-File -FilePath "setup_enterprise.rb" -Encoding UTF8
                        Invoke-Expression "$DockerComposeCmd exec rails bundle exec rails runner setup_enterprise.rb"
                        Remove-Item "setup_enterprise.rb" -ErrorAction SilentlyContinue
                        
                        Write-Host ""
                        Write-Host "[SUCCESS] Setup inicial concluído!" -ForegroundColor Green
                        Write-Host "[INFO] Usuário padrão criado:" -ForegroundColor Cyan
                        Write-Host "  Email: john@acme.inc" -ForegroundColor White
                        Write-Host "  Senha: Password1!" -ForegroundColor White
                        Write-Host "[INFO] Plano: Enterprise (todas as features habilitadas)" -ForegroundColor Cyan
                        Write-Host ""
                    } else {
                        Write-Host "[ERROR] Falha ao executar seeds!" -ForegroundColor Red
                    }
                } else {
                    Write-Host "[ERROR] Falha ao executar chatwoot_prepare!" -ForegroundColor Red
                }
            }
            
            Write-Host ""
            Write-Host "[SUCCESS] Ambiente iniciado com sucesso!" -ForegroundColor Green
            Write-Host ""
            Write-Host "SERVIÇOS DISPONÍVEIS:" -ForegroundColor Cyan
            Write-Host "  Chatwit (via ngrok):  https://$NgrokUrl" -ForegroundColor White
            Write-Host "  Chatwit (local):      http://localhost:3000" -ForegroundColor White
            Write-Host "  Vite Dev Server:      http://localhost:3036" -ForegroundColor White  
            Write-Host "  MailHog:              http://localhost:8025" -ForegroundColor White
            Write-Host "  Ngrok Interface:      http://localhost:4040" -ForegroundColor White
            Write-Host "  PostgreSQL:           localhost:5433" -ForegroundColor White
            Write-Host "  Redis:                localhost:6380" -ForegroundColor White
            Write-Host ""
            Write-Host "COMO ACESSAR:" -ForegroundColor Cyan
            Write-Host "  1. Abra https://$NgrokUrl (acesso público)" -ForegroundColor White
            Write-Host "  2. Faça login com john@acme.inc / Password1!" -ForegroundColor White
            Write-Host ""
            Write-Host "[INFO] Pressione Ctrl+C para parar o ambiente" -ForegroundColor Yellow
            Write-Host ""
            
            if ($Logs -and $Detach) {
                Write-Host "[LOGS] Mostrando logs..." -ForegroundColor Cyan
                Invoke-Expression "$DockerComposeCmd logs -f"
            }
        } else {
            Write-Host "[ERROR] Falha ao iniciar ambiente!" -ForegroundColor Red
            exit 1
        }
    }
    
    "down" {
        Write-Host "[STOP] Parando ambiente de desenvolvimento..." -ForegroundColor Yellow
        Invoke-Expression "$DockerComposeCmd down"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[SUCCESS] Ambiente parado com sucesso!" -ForegroundColor Green
        }
    }
    
    "restart" {
        Write-Host "[RESTART] Reiniciando ambiente..." -ForegroundColor Yellow
        Invoke-Expression "$DockerComposeCmd restart"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[SUCCESS] Ambiente reiniciado!" -ForegroundColor Green
        }
    }
    
    "logs" {
        Write-Host "[LOGS] Mostrando logs dos serviços..." -ForegroundColor Cyan
        Invoke-Expression "$DockerComposeCmd logs -f"
    }
    
    "status" {
        Write-Host "[STATUS] Status dos containers:" -ForegroundColor Cyan
        Invoke-Expression "$DockerComposeCmd ps"
        Write-Host ""
        Write-Host "[NGROK] Status do túnel:" -ForegroundColor Cyan
        if (Get-NgrokStatus) {
            Write-Host "  Ngrok rodando (container Docker)" -ForegroundColor Green
            Write-Host "  URL: https://$NgrokUrl" -ForegroundColor Cyan
            Write-Host "  Interface web: http://localhost:4040" -ForegroundColor Cyan
        } else {
            Write-Host "  Ngrok não está rodando" -ForegroundColor Yellow
        }
    }
    
    "shell" {
        Write-Host "[SHELL] Entrando no container Rails..." -ForegroundColor Cyan
        Invoke-Expression "$DockerComposeCmd exec rails bash"
    }
    
    "migrate" {
        Write-Host "[MIGRATE] Executando migrações pendentes..." -ForegroundColor Green
        Invoke-Expression "$DockerComposeCmd exec rails bundle exec rails db:migrate"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[SUCCESS] Migrações executadas com sucesso!" -ForegroundColor Green
        } else {
            Write-Host "[ERROR] Falha ao executar migrações!" -ForegroundColor Red
        }
    }
    
    "db-setup" {
        Write-Host "[DB] Configurando banco de dados..." -ForegroundColor Green
        Write-Host "[DB] Executando chatwoot_prepare..." -ForegroundColor Cyan
        Invoke-Expression "$DockerComposeCmd exec rails bundle exec rails db:chatwoot_prepare"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[DB] Executando seeds..." -ForegroundColor Cyan
            Invoke-Expression "$DockerComposeCmd exec rails bundle exec rails db:seed"
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[ENTERPRISE] Habilitando features Enterprise..." -ForegroundColor Cyan
                $enterpriseScript = @"
puts 'Habilitando Enterprise...'
account = Account.first
enterprise_features = ['disable_branding', 'audit_logs', 'response_bot', 'sla', 'captain_integration', 'custom_roles']
account.enable_features(*enterprise_features)
InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN').update!(value: 'enterprise')
InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN_QUANTITY').update!(value: '999')
puts 'Enterprise habilitado com sucesso!'
"@
                $enterpriseScript | Out-File -FilePath "setup_enterprise.rb" -Encoding UTF8
                Invoke-Expression "$DockerComposeCmd exec rails bundle exec rails runner setup_enterprise.rb"
                Remove-Item "setup_enterprise.rb" -ErrorAction SilentlyContinue
                
                Write-Host "[SUCCESS] Banco configurado com sucesso!" -ForegroundColor Green
                Write-Host "[INFO] Usuário criado: john@acme.inc / Password1!" -ForegroundColor Cyan
                Write-Host "[INFO] Plano: Enterprise (todas as features habilitadas)" -ForegroundColor Cyan
            } else {
                Write-Host "[ERROR] Falha ao executar seeds!" -ForegroundColor Red
            }
        } else {
            Write-Host "[ERROR] Falha ao executar chatwoot_prepare!" -ForegroundColor Red
        }
    }
    
    "db-reset" {
        Write-Host "[DB] Resetando banco de dados..." -ForegroundColor Yellow
        Write-Host "[WARNING] Isso irá apagar todos os dados! Continuar? (y/N): " -ForegroundColor Red -NoNewline
        $confirm = Read-Host
        
        if ($confirm -eq "y" -or $confirm -eq "Y") {
            Write-Host "[DB] Removendo banco..." -ForegroundColor Yellow
            Invoke-Expression "$DockerComposeCmd exec rails bundle exec rails db:drop"
            
            Write-Host "[DB] Executando chatwoot_prepare..." -ForegroundColor Cyan
            Invoke-Expression "$DockerComposeCmd exec rails bundle exec rails db:chatwoot_prepare"
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[DB] Executando seeds..." -ForegroundColor Cyan
                Invoke-Expression "$DockerComposeCmd exec rails bundle exec rails db:seed"
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "[ENTERPRISE] Habilitando features Enterprise..." -ForegroundColor Cyan
                    $enterpriseScript = @"
puts 'Habilitando Enterprise...'
account = Account.first
enterprise_features = ['disable_branding', 'audit_logs', 'response_bot', 'sla', 'captain_integration', 'custom_roles']
account.enable_features(*enterprise_features)
InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN').update!(value: 'enterprise')
InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN_QUANTITY').update!(value: '999')
puts 'Enterprise habilitado com sucesso!'
"@
                    $enterpriseScript | Out-File -FilePath "setup_enterprise.rb" -Encoding UTF8
                    Invoke-Expression "$DockerComposeCmd exec rails bundle exec rails runner setup_enterprise.rb"
                    Remove-Item "setup_enterprise.rb" -ErrorAction SilentlyContinue
                    
                    Write-Host "[SUCCESS] Banco resetado!" -ForegroundColor Green
                    Write-Host "[INFO] Usuário criado: john@acme.inc / Password1!" -ForegroundColor Cyan
                    Write-Host "[INFO] Plano: Enterprise (todas as features habilitadas)" -ForegroundColor Cyan
                } else {
                    Write-Host "[ERROR] Falha ao executar seeds!" -ForegroundColor Red
                }
            } else {
                Write-Host "[ERROR] Falha ao executar chatwoot_prepare!" -ForegroundColor Red
            }
        } else {
            Write-Host "[CANCELLED] Operação cancelada." -ForegroundColor Yellow
        }
    }
    
    "clean" {
        Write-Host "[CLEAN] Limpando containers e volumes..." -ForegroundColor Red
        
        if (-not $Force) {
            Write-Host "[WARNING] Isso irá remover containers, imagens e volumes! Continuar? (y/N): " -ForegroundColor Red -NoNewline
            $confirm = Read-Host
            
            if ($confirm -ne "y" -and $confirm -ne "Y") {
                Write-Host "[CANCELLED] Operação cancelada." -ForegroundColor Yellow
                exit 0
            }
        }
        
        Write-Host "[CLEAN] Parando containers..." -ForegroundColor Yellow
        Invoke-Expression "$DockerComposeCmd down -v --remove-orphans"
        
        Write-Host "[CLEAN] Removendo imagens..." -ForegroundColor Yellow
        docker rmi chatwit:development chatwit-rails:development chatwit-vite:development 2>$null
        
        Write-Host "[CLEAN] Removendo volumes órfãos..." -ForegroundColor Yellow
        docker volume prune -f
        
        Write-Host "[SUCCESS] Limpeza concluída!" -ForegroundColor Green
    }
    
    default {
        Write-Host "[ERROR] Ação '$Action' não reconhecida!" -ForegroundColor Red
        Write-Host ""
        Show-Help
        exit 1
    }
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan 