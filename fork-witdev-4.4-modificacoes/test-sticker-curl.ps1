param(
    [string]$ConversationId = "1987",
    [string]$AccountId = "3",
    [string]$InboxId = "4",
    [string]$StickerPath = "public\webp-stick-test\File.webp"
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  TESTE DE ENVIO DE STICKER WEBP (cURL)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se o arquivo existe
if (-not (Test-Path $StickerPath)) {
    Write-Host "[ERROR] Arquivo sticker nao encontrado: $StickerPath" -ForegroundColor Red
    exit 1
}

# Verificar se o ambiente está rodando
Write-Host "[INFO] Verificando se o ambiente está rodando..." -ForegroundColor Cyan
$response = Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing -ErrorAction SilentlyContinue

if (-not $response) {
    Write-Host "[ERROR] Chatwit não está rodando em http://localhost:3000" -ForegroundColor Red
    Write-Host "[INFO] Execute: .\build-desenvolvimento.ps1 up" -ForegroundColor Yellow
    exit 1
}

Write-Host "[SUCCESS] Chatwit está rodando!" -ForegroundColor Green

# Configurações da requisição
$baseUrl = "http://localhost:3000"
$uploadUrl = "$baseUrl/app/accounts/$AccountId/inbox/$InboxId/conversations/$ConversationId/messages"

Write-Host "[INFO] URL de upload: $uploadUrl" -ForegroundColor Cyan
Write-Host "[INFO] Arquivo: $StickerPath" -ForegroundColor Cyan
Write-Host ""

# Verificar se cURL está disponível
try {
    $curlVersion = curl --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SUCCESS] cURL encontrado!" -ForegroundColor Green
    } else {
        throw "cURL não encontrado"
    }
} catch {
    Write-Host "[ERROR] cURL não está disponível no sistema" -ForegroundColor Red
    Write-Host "[INFO] Instale o cURL ou use o script test-sticker-upload.ps1" -ForegroundColor Yellow
    exit 1
}

# Construir comando cURL
$curlCmd = @(
    "curl",
    "-X", "POST",
    "`"$uploadUrl`"",
    "-H", "`"Content-Type: multipart/form-data`"",
    "-H", "`"Accept: application/json`"",
    "-F", "`"message_type=incoming`"",
    "-F", "`"content_type=sticker`"",
    "-F", "`"attachments=@$StickerPath`"",
    "-v"  # Verbose para debug
) -join " "

Write-Host "[UPLOAD] Executando comando cURL..." -ForegroundColor Green
Write-Host "[CMD] $curlCmd" -ForegroundColor Yellow
Write-Host ""

# Executar o comando
try {
    $result = Invoke-Expression $curlCmd
    
    Write-Host ""
    Write-Host "[SUCCESS] Upload concluído!" -ForegroundColor Green
    Write-Host "[INFO] Resposta do servidor:" -ForegroundColor Cyan
    Write-Host $result -ForegroundColor White
    
} catch {
    Write-Host "[ERROR] Erro durante o upload:" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "[NEXT] Verifique a conversa em:" -ForegroundColor Green
Write-Host "  $baseUrl/app/accounts/$AccountId/inbox/$InboxId/conversations/$ConversationId" -ForegroundColor White

Write-Host ""
Write-Host "[INFO] Se o upload falhar, tente:" -ForegroundColor Cyan
Write-Host "  1. Fazer login manualmente no Chatwit primeiro" -ForegroundColor White
Write-Host "  2. Verificar se a conversa existe" -ForegroundColor White
Write-Host "  3. Verificar logs do Rails: .\build-desenvolvimento.ps1 logs" -ForegroundColor White

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
