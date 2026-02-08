#!/usr/bin/env pwsh

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  VERIFICADOR DE STATUS DA TELEMETRIA" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Verifica se estamos no diretorio correto
if (-not (Test-Path "Gemfile")) {
    Write-Host "X Este script deve ser executado na raiz do projeto Chatwoot!" -ForegroundColor Red
    exit 1
}

Write-Host "Verificando status da telemetria..." -ForegroundColor Yellow
Write-Host ""

# Funcao para verificar variavel de ambiente
function Check-EnvVariable {
    param($name, $description)
    
    $value = ""
    if (Test-Path ".env") {
        $content = Get-Content ".env"
        $line = $content | Where-Object { $_ -match "^$name=" }
        if ($line) {
            $value = ($line -split "=", 2)[1]
        }
    }
    
    if ($value -eq "true" -and $name -eq "DISABLE_TELEMETRY") {
        Write-Host "   OK $description" -ForegroundColor Green
        Write-Host "      $name=$value" -ForegroundColor DarkGreen
    } elseif ([string]::IsNullOrEmpty($value) -and $name -ne "DISABLE_TELEMETRY") {
        Write-Host "   OK $description" -ForegroundColor Green
        Write-Host "      $name=$value (vazio/desabilitado)" -ForegroundColor DarkGreen
    } elseif ($name -eq "CHATWOOT_HUB_URL" -and $value -eq "http://localhost:9999") {
        Write-Host "   OK $description" -ForegroundColor Green
        Write-Host "      $name=$value (redirecionado)" -ForegroundColor DarkGreen
    } else {
        Write-Host "   AVISO $description" -ForegroundColor Yellow
        Write-Host "      $name=$value" -ForegroundColor DarkYellow
    }
    Write-Host ""
}

Write-Host "VERIFICANDO CONFIGURACOES DO ARQUIVO .env:" -ForegroundColor Cyan
Write-Host ""

Check-EnvVariable "DISABLE_TELEMETRY" "Telemetria principal desabilitada"
Check-EnvVariable "ANALYTICS_TOKEN" "Token de analytics removido" 
Check-EnvVariable "HELP_CENTER_ANALYTICS_ID" "Analytics do help center removido"
Check-EnvVariable "CHATWOOT_INBOX_TOKEN" "Token de suporte Chatwoot removido"
Check-EnvVariable "CHATWOOT_INBOX_HMAC_KEY" "Chave HMAC de suporte removida"
Check-EnvVariable "CHATWOOT_SUPPORT_WEBSITE_TOKEN" "Token de website de suporte removido"
Check-EnvVariable "CHATWOOT_SUPPORT_SCRIPT_URL" "URL de script de suporte removida"
Check-EnvVariable "CHATWOOT_SUPPORT_IDENTIFIER_HASH" "Hash de identificacao removido"
Check-EnvVariable "CHATWOOT_HUB_URL" "URL do hub redirecionada"

Write-Host "VERIFICANDO CONFIGURACOES NO CODIGO:" -ForegroundColor Cyan
Write-Host ""

# Verifica se o codigo de telemetria esta presente
$hubFile = "lib/chatwoot_hub.rb"
if (Test-Path $hubFile) {
    $hubContent = Get-Content $hubFile -Raw
    
    if ($hubContent -match "ENV\['DISABLE_TELEMETRY'\]") {
        Write-Host "   OK Verificacoes de DISABLE_TELEMETRY presentes no codigo" -ForegroundColor Green
    } else {
        Write-Host "   X Verificacoes de DISABLE_TELEMETRY ausentes no codigo" -ForegroundColor Red
    }
    
    if ($hubContent -match "return if ENV\['DISABLE_TELEMETRY'\]") {
        Write-Host "   OK Protecao contra envio de eventos implementada" -ForegroundColor Green
    } else {
        Write-Host "   X Protecao contra envio de eventos nao encontrada" -ForegroundColor Red
    }
    
    if ($hubContent -match "unless ENV\['DISABLE_TELEMETRY'\]") {
        Write-Host "   OK Protecao contra metricas implementada" -ForegroundColor Green
    } else {
        Write-Host "   X Protecao contra metricas nao encontrada" -ForegroundColor Red
    }
} else {
    Write-Host "   X Arquivo $hubFile nao encontrado" -ForegroundColor Red
}

Write-Host ""

# Cria script para verificar no banco de dados
$checkScript = @'
# Verifica configuracoes de analytics no banco
analytics_configs = GlobalConfig.where(name: ['ANALYTICS_TOKEN', 'HELP_CENTER_ANALYTICS_ID'])
support_configs = GlobalConfig.where(name: [
  'CHATWOOT_INBOX_TOKEN', 
  'CHATWOOT_INBOX_HMAC_KEY',
  'CHATWOOT_SUPPORT_WEBSITE_TOKEN',
  'CHATWOOT_SUPPORT_SCRIPT_URL', 
  'CHATWOOT_SUPPORT_IDENTIFIER_HASH'
])

puts "CONFIGURACOES DE ANALYTICS NO BANCO:"
if analytics_configs.any?
  analytics_configs.each do |config|
    status = config.value.blank? ? "OK VAZIO" : "AVISO CONTEM VALOR"
    puts "   #{config.name}: #{status}"
  end
else
  puts "   OK Nenhuma configuracao de analytics encontrada"
end

puts "\nCONFIGURACOES DE SUPORTE NO BANCO:"
if support_configs.any?
  support_configs.each do |config|
    status = config.value.blank? ? "OK VAZIO" : "AVISO CONTEM VALOR"
    puts "   #{config.name}: #{status}"
  end
else
  puts "   OK Nenhuma configuracao de suporte encontrada"
end

puts "\nIDENTIFICADOR DA INSTALACAO:"
identifier = InstallationConfig.find_by(name: 'INSTALLATION_IDENTIFIER')
if identifier
  puts "   ID: #{identifier.value[0..8]}... (primeiros 8 caracteres)"
  puts "   AVISO Este ID e usado para identificar sua instalacao"
else
  puts "   OK Nenhum identificador de instalacao encontrado"
end
'@

$checkScript | Set-Content "temp_check_telemetry.rb"

Write-Host "VERIFICANDO CONFIGURACOES NO BANCO DE DADOS:" -ForegroundColor Cyan
Write-Host ""

if (Get-Command "rails" -ErrorAction SilentlyContinue) {
    rails runner temp_check_telemetry.rb
    Remove-Item "temp_check_telemetry.rb" -ErrorAction SilentlyContinue
} else {
    Write-Host "   AVISO Comando 'rails' nao encontrado" -ForegroundColor Yellow
    Write-Host "   Execute manualmente: rails runner temp_check_telemetry.rb" -ForegroundColor White
    Write-Host ""
}

Write-Host ""
Write-Host "RESUMO DO STATUS:" -ForegroundColor Cyan
Write-Host ""

# Determina status geral
$envFile = ".env"
$telemetryDisabled = $false
$analyticsRemoved = $false

if (Test-Path $envFile) {
    $content = Get-Content $envFile
    $telemetryDisabled = ($content | Where-Object { $_ -match "^DISABLE_TELEMETRY=true" }) -ne $null
    $analyticsLine = $content | Where-Object { $_ -match "^ANALYTICS_TOKEN=" }
    $analyticsRemoved = $analyticsLine -and ($analyticsLine -split "=", 2)[1] -eq ""
}

if ($telemetryDisabled -and $analyticsRemoved) {
    Write-Host "   TELEMETRIA TOTALMENTE DESABILITADA" -ForegroundColor Green
    Write-Host "   OK Sua instalacao nao enviara dados para o Chatwoot" -ForegroundColor Green
} elseif ($telemetryDisabled) {
    Write-Host "   TELEMETRIA PRINCIPAL DESABILITADA" -ForegroundColor Yellow
    Write-Host "   AVISO Alguns analytics do frontend podem ainda estar ativos" -ForegroundColor Yellow
} else {
    Write-Host "   X TELEMETRIA AINDA ATIVA" -ForegroundColor Red
    Write-Host "   AVISO Execute ./disable-telemetry.ps1 para desabilitar" -ForegroundColor Red
}

Write-Host ""
Write-Host "VERIFICACAO RECOMENDADA:" -ForegroundColor Cyan
Write-Host "   1. Monitore os logs da aplicacao apos reiniciar" -ForegroundColor White
Write-Host "   2. Procure por conexoes com hub.chatwoot.com" -ForegroundColor White
Write-Host "   3. Use ferramentas como netstat para verificar conexoes ativas" -ForegroundColor White
Write-Host ""

Write-Host "Verificacao concluida!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan 