param(
    [string]$ConversationId = "1987",
    [string]$AccountId = "3",
    [string]$InboxId = "4",
    [string]$StickerPath = "public\webp-stick-test\File.webp",
    [switch]$SkipChecks
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  TESTE STICKER WEBP (PowerShell Nativo)" -ForegroundColor Cyan
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

Write-Host "[INFO] URL: $uploadUrl" -ForegroundColor Cyan
Write-Host "[INFO] Arquivo: $StickerPath" -ForegroundColor Cyan

# Preparar dados do upload usando PowerShell nativo
try {
    # Ler o arquivo
    $fileBytes = [System.IO.File]::ReadAllBytes($StickerPath)
    $fileName = [System.IO.Path]::GetFileName($StickerPath)
    
    # Criar boundary para multipart/form-data
    $boundary = [System.Guid]::NewGuid().ToString()
    $LF = "`r`n"
    
    # Construir o corpo da requisição multipart
    $bodyLines = @(
        "--$boundary",
        "Content-Disposition: form-data; name=`"message_type`"",
        "",
        "incoming",
        "--$boundary",
        "Content-Disposition: form-data; name=`"content_type`"",
        "",
        "sticker",
        "--$boundary",
        "Content-Disposition: form-data; name=`"attachments`"; filename=`"$fileName`"",
        "Content-Type: image/webp",
        "",
        [System.Text.Encoding]::UTF8.GetString($fileBytes),
        "--$boundary--"
    )
    
    $body = $bodyLines -join $LF
    
    # Headers da requisição
    $headers = @{
        "Content-Type" = "multipart/form-data; boundary=$boundary"
        "Accept" = "application/json"
        "X-Requested-With" = "XMLHttpRequest"
    }
    
    Write-Host "[INFO] Enviando requisição..." -ForegroundColor Cyan
    
    # Fazer a requisição
    $uploadResponse = Invoke-WebRequest -Uri $uploadUrl -Method POST -Body $body -Headers $headers -UseBasicParsing -TimeoutSec 30
    
    if ($uploadResponse.StatusCode -eq 200 -or $uploadResponse.StatusCode -eq 201) {
        Write-Host "[SUCCESS] Sticker enviado com sucesso!" -ForegroundColor Green
        Write-Host "[INFO] Status Code: $($uploadResponse.StatusCode)" -ForegroundColor Cyan
        
        # Tentar parsear a resposta JSON
        try {
            $responseData = $uploadResponse.Content | ConvertFrom-Json
            Write-Host "[INFO] ID da mensagem: $($responseData.id)" -ForegroundColor Cyan
        } catch {
            Write-Host "[INFO] Resposta: $($uploadResponse.Content)" -ForegroundColor Cyan
        }
        
    } else {
        Write-Host "[ERROR] Falha no upload. Status: $($uploadResponse.StatusCode)" -ForegroundColor Red
        Write-Host "[INFO] Resposta: $($uploadResponse.Content)" -ForegroundColor Yellow
        exit 1
    }
    
} catch {
    Write-Host "[ERROR] Erro durante upload: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode
        Write-Host "[INFO] Status Code: $statusCode" -ForegroundColor Yellow
        
        # Tentar ler o conteúdo do erro
        try {
            $errorStream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorStream)
            $errorContent = $reader.ReadToEnd()
            Write-Host "[INFO] Erro detalhado: $errorContent" -ForegroundColor Yellow
        } catch {
            Write-Host "[INFO] Não foi possível ler detalhes do erro" -ForegroundColor Yellow
        }
    }
    
    Write-Host "[TIP] Faça login no Chatwit primeiro: http://localhost:3000" -ForegroundColor Yellow
    Write-Host "[TIP] Verifique se a conversa existe: $baseUrl/app/accounts/$AccountId/inbox/$InboxId/conversations/$ConversationId" -ForegroundColor Yellow
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
