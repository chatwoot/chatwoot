param(
    [Parameter(Position=0)]
    [string]$Action = "up",
    [switch]$Build,
    [switch]$Detach,
    [switch]$Force,
    [switch]$Logs,
    [switch]$Nocache
)

$ErrorActionPreference = "Stop"

# Configuracoes
$ComposeFile = "docker-compose.yaml"
$ProjectName = "chatwit-dev"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  CHATWIT - AMBIENTE DE DESENVOLVIMENTO  " -ForegroundColor Cyan  
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se o arquivo .env existe
if (-not (Test-Path ".env")) {
    Write-Host "[WARNING] Arquivo .env nao encontrado!" -ForegroundColor Yellow
    if (Test-Path ".env.example") {
        Write-Host "[INFO] Copiando .env.example para .env..." -ForegroundColor Cyan
        Copy-Item ".env.example" ".env"
        Write-Host "[SUCCESS] Arquivo .env criado! Configure as variaveis antes de continuar." -ForegroundColor Green
        Write-Host "[INFO] Editando .env..." -ForegroundColor Cyan
        notepad .env
        Write-Host "[INFO] Pressione Enter apos configurar o .env..." -ForegroundColor Yellow
        Read-Host
    } else {
        Write-Host "[ERROR] Arquivo .env.example nao encontrado!" -ForegroundColor Red
        exit 1
    }
}

# Funcao para mostrar ajuda
function Show-Help {
    Write-Host "USO:" -ForegroundColor Green
    Write-Host "  .\build-desenvolvimento.ps1 [ACAO] [OPCOES]" -ForegroundColor White
    Write-Host ""
    Write-Host "ACOES:" -ForegroundColor Green
    Write-Host "  up          - Subir todos os servicos (padrao)" -ForegroundColor White
    Write-Host "  down        - Parar todos os servicos" -ForegroundColor White
    Write-Host "  restart     - Reiniciar todos os servicos" -ForegroundColor White
    Write-Host "  logs        - Mostrar logs dos servicos" -ForegroundColor White
    Write-Host "  status      - Mostrar status dos containers" -ForegroundColor White
    Write-Host "  shell       - Entrar no container Rails" -ForegroundColor White
    Write-Host "  migrate     - Executar migracoes pendentes" -ForegroundColor White
    Write-Host "  db-setup    - Configurar banco de dados" -ForegroundColor White
    Write-Host "  db-reset    - Resetar banco de dados" -ForegroundColor White
    Write-Host "  clean       - Limpar containers e volumes" -ForegroundColor White
    Write-Host ""
    Write-Host "OPCOES:" -ForegroundColor Green
    Write-Host "  -Build      - Rebuild imagens (so primeira vez ou mudancas em deps)" -ForegroundColor White
    Write-Host "  -Nocache    - Rebuild imagens sem cache (forcar rebuild completo)" -ForegroundColor White
    Write-Host "  -Detach     - Executar em background" -ForegroundColor White
    Write-Host "  -Force      - Forcar operacao (para clean)" -ForegroundColor White
    Write-Host "  -Logs       - Mostrar logs apos subir" -ForegroundColor White
    Write-Host ""
    Write-Host "EXEMPLOS:" -ForegroundColor Green
    Write-Host "  .\build-desenvolvimento.ps1 up -Build       # Primeira vez (setup completo)" -ForegroundColor Cyan
    Write-Host "  .\build-desenvolvimento.ps1 up -Nocache     # Rebuild completo sem cache" -ForegroundColor Cyan
    Write-Host "  .\build-desenvolvimento.ps1 up              # Uso diario (hot reload)" -ForegroundColor Cyan
    Write-Host "  .\build-desenvolvimento.ps1 up -Detach      # Background" -ForegroundColor Cyan
    Write-Host "  .\build-desenvolvimento.ps1 down" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "PRIMEIRA VEZ:" -ForegroundColor Yellow
    Write-Host "  Use 'up -Build' para setup completo (imagens + banco + seeds)" -ForegroundColor White
    Write-Host "  Cria usuario: john@acme.inc / Password1!" -ForegroundColor White
    Write-Host ""
    Write-Host "NOTA:" -ForegroundColor Yellow
    Write-Host "  Hot reload ativo! Mudancas em .rb/.vue/.js aparecem automaticamente" -ForegroundColor White
    Write-Host "  Use -Build so na primeira vez ou quando mudar dependencias" -ForegroundColor White
}

# Verificar se e pedido de ajuda
if ($Action -eq "help" -or $Action -eq "-h" -or $Action -eq "--help") {
    Show-Help
    exit 0
}

# Preparar comandos docker-compose
$DockerComposeCmd = "docker-compose -f $ComposeFile -p $ProjectName"

Write-Host "[INFO] Projeto: $ProjectName" -ForegroundColor Cyan
Write-Host "[INFO] Arquivo: $ComposeFile" -ForegroundColor Cyan
Write-Host "[INFO] Acao: $Action" -ForegroundColor Cyan
Write-Host ""

switch ($Action.ToLower()) {
    "up" {
        if ($Build) {
            Write-Host "[BUILD] Subindo ambiente com rebuild (primeira vez ou apos mudancas em dependencias)..." -ForegroundColor Green
        } else {
            Write-Host "[UP] Subindo ambiente de desenvolvimento (hot reload ativo)..." -ForegroundColor Green
            Write-Host "[INFO] Hot reload ativo! Mudancas no codigo aparecem automaticamente." -ForegroundColor Cyan
        }
        
        $cmd = "$DockerComposeCmd up"
        if ($Build) { $cmd += " --build" }
        if ($Nocache) { 
            Write-Host "[BUILD] Executando build sem cache..." -ForegroundColor Yellow
            Invoke-Expression "$DockerComposeCmd build --no-cache"
            if ($LASTEXITCODE -ne 0) {
                Write-Host "[ERROR] Falha no build!" -ForegroundColor Red
                exit 1
            }
        }
        if ($Detach) { $cmd += " -d" }
        
        Write-Host "[EXEC] $cmd" -ForegroundColor Yellow
        Invoke-Expression $cmd
        
        if ($LASTEXITCODE -eq 0) {
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
                        Write-Host "[SUCCESS] Setup inicial concluido!" -ForegroundColor Green
                        Write-Host "[INFO] Usuario padrao criado:" -ForegroundColor Cyan
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
            Write-Host "SERVICOS DISPONIVEIS:" -ForegroundColor Cyan
            Write-Host "  Chatwit (Rails):     http://localhost:3000" -ForegroundColor White
            Write-Host "  Vite Dev Server:     http://localhost:3036" -ForegroundColor White  
            Write-Host "  MailHog:             http://localhost:8025" -ForegroundColor White
            Write-Host "  PostgreSQL:          localhost:5432" -ForegroundColor White
            Write-Host "  Redis:               localhost:6379" -ForegroundColor White
            Write-Host ""
            Write-Host "COMO ACESSAR:" -ForegroundColor Cyan
            Write-Host "  1. Abra http://localhost:3000" -ForegroundColor White
            Write-Host "  2. Faca login com john@acme.inc / Password1!" -ForegroundColor White
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
        Write-Host "[LOGS] Mostrando logs dos servicos..." -ForegroundColor Cyan
        Invoke-Expression "$DockerComposeCmd logs -f"
    }
    
    "status" {
        Write-Host "[STATUS] Status dos containers:" -ForegroundColor Cyan
        Invoke-Expression "$DockerComposeCmd ps"
    }
    
    "shell" {
        Write-Host "[SHELL] Entrando no container Rails..." -ForegroundColor Cyan
        Invoke-Expression "$DockerComposeCmd exec rails bash"
    }
    
    "migrate" {
        Write-Host "[MIGRATE] Executando migracoes pendentes..." -ForegroundColor Green
        Invoke-Expression "$DockerComposeCmd exec rails bundle exec rails db:migrate"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[SUCCESS] Migracoes executadas com sucesso!" -ForegroundColor Green
        } else {
            Write-Host "[ERROR] Falha ao executar migracoes!" -ForegroundColor Red
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
                Write-Host "[INFO] Usuario criado: john@acme.inc / Password1!" -ForegroundColor Cyan
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
        Write-Host "[WARNING] Isso ira apagar todos os dados! Continuar? (y/N): " -ForegroundColor Red -NoNewline
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
                    Write-Host "[INFO] Usuario criado: john@acme.inc / Password1!" -ForegroundColor Cyan
                    Write-Host "[INFO] Plano: Enterprise (todas as features habilitadas)" -ForegroundColor Cyan
                } else {
                    Write-Host "[ERROR] Falha ao executar seeds!" -ForegroundColor Red
                }
            } else {
                Write-Host "[ERROR] Falha ao executar chatwoot_prepare!" -ForegroundColor Red
            }
        } else {
            Write-Host "[CANCELLED] Operacao cancelada." -ForegroundColor Yellow
        }
    }
    
    "clean" {
        Write-Host "[CLEAN] Limpando containers e volumes..." -ForegroundColor Red
        
        if (-not $Force) {
            Write-Host "[WARNING] Isso ira remover containers, imagens e volumes! Continuar? (y/N): " -ForegroundColor Red -NoNewline
            $confirm = Read-Host
            
            if ($confirm -ne "y" -and $confirm -ne "Y") {
                Write-Host "[CANCELLED] Operacao cancelada." -ForegroundColor Yellow
                exit 0
            }
        }
        
        Write-Host "[CLEAN] Parando containers..." -ForegroundColor Yellow
        Invoke-Expression "$DockerComposeCmd down -v --remove-orphans"
        
        Write-Host "[CLEAN] Removendo imagens..." -ForegroundColor Yellow
        docker rmi chatwit:development chatwit-rails:development chatwit-vite:development 2>$null
        
        Write-Host "[CLEAN] Removendo volumes orfaos..." -ForegroundColor Yellow
        docker volume prune -f
        
        Write-Host "[SUCCESS] Limpeza concluida!" -ForegroundColor Green
    }
    
    default {
        Write-Host "[ERROR] Acao '$Action' nao reconhecida!" -ForegroundColor Red
        Write-Host ""
        Show-Help
        exit 1
    }
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan 