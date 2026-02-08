param(
    [string]$ConversationId = "1987",
    [string]$AccountId = "3",
    [string]$InboxId = "4",
    [string]$StickerPath = "public\webp-stick-test\File.webp",
    [switch]$SkipChecks
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  TESTE RÁPIDO DE STICKER WEBP" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se o arquivo existe
if (-not (Test-Path $StickerPath)) {
    Write-Host "[ERROR] Arquivo sticker nao encontrado: $StickerPath" -ForegroundColor Red
    exit 1
}

$baseUrl = "http://localhost:3000"

# Pular verificações se solicitado
if (-not $SkipChecks) {
    Write-Host "[INFO] Verificações rápidas..." -ForegroundColor Cyan
    
    # Verificação rápida de containers
    $railsContainer = docker ps --format "{{.Names}}" 2>$null | Select-String "chatwit-dev-rails-1"
    if (-not $railsContainer) {
        Write-Host "[ERROR] Container Rails não encontrado! Execute: .\build-desenvolvimento.ps1 up" -ForegroundColor Red
        exit 1
    }
    Write-Host "[OK] Container Rails rodando" -ForegroundColor Green
}

Write-Host ""
Write-Host "[UPLOAD] Enviando sticker..." -ForegroundColor Green

# URL de upload CORRIGIDA - usando a API correta
$uploadUrl = "$baseUrl/api/v1/accounts/$AccountId/conversations/$ConversationId/messages"

# Comando cURL corrigido - usando array para evitar problemas de parsing
$curlArgs = @(
    "-X", "POST",
    $uploadUrl,
    "-H", "Content-Type: multipart/form-data",
    "-F", "message_type=incoming",
    "-F", "content_type=sticker",
    "-F", "attachments=@$StickerPath",
    "-s",
    "--max-time", "30"
)

Write-Host "[CMD] curl $($curlArgs -join ' ')" -ForegroundColor Yellow

try {
    $uploadResult = & curl @curlArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SUCCESS] Sticker enviado com sucesso!" -ForegroundColor Green
        
        # Tentar mostrar resposta
        if ($uploadResult) {
            try {
                $responseData = $uploadResult | ConvertFrom-Json
                Write-Host "[INFO] ID da mensagem: $($responseData.id)" -ForegroundColor Cyan
            } catch {
                Write-Host "[INFO] Resposta: $uploadResult" -ForegroundColor Cyan
            }
        }
        
    } else {
        Write-Host "[ERROR] Falha no upload (código: $LASTEXITCODE)" -ForegroundColor Red
        Write-Host "[INFO] Resposta: $uploadResult" -ForegroundColor Yellow
        Write-Host "[TIP] Faça login no Chatwit primeiro: http://localhost:3000" -ForegroundColor Yellow
        Write-Host "[TIP] Verifique se a conversa existe: $baseUrl/app/accounts/$AccountId/inbox/$InboxId/conversations/$ConversationId" -ForegroundColor Yellow
        exit 1
    }
    
} catch {
    Write-Host "[ERROR] Erro durante upload: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[SUCCESS] Teste concluído!" -ForegroundColor Green
Write-Host ""
Write-Host "[NEXT] Verifique:" -ForegroundColor Cyan
Write-Host "  Conversa: $baseUrl/app/accounts/$AccountId/inbox/$InboxId/conversations/$ConversationId" -ForegroundColor White
Write-Host "  Biblioteca: $baseUrl/app/accounts/$AccountId/stickers" -ForegroundColor White
Write-Host ""

# Abrir conversa automaticamente
Write-Host "[AUTO] Abrindo conversa no navegador..." -ForegroundColor Cyan
Start-Process "$baseUrl/app/accounts/$AccountId/inbox/$InboxId/conversations/$ConversationId"

Write-Host "==========================================" -ForegroundColor Cyan
