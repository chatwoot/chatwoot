param(
    [string]$ConversationId = "1987",
    [string]$AccountId = "3",
    [string]$InboxId = "4",
    [string]$StickerPath = "public\webp-stick-test\File.webp"
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  TESTE DE ENVIO DE STICKER WEBP" -ForegroundColor Cyan
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

# Simular login e obter token de autenticação
Write-Host "[AUTH] Simulando login para obter token..." -ForegroundColor Cyan

# Primeiro, vamos tentar fazer login
$loginData = @{
    email = "john@acme.inc"
    password = "Password1!"
}

try {
    $loginResponse = Invoke-WebRequest -Uri "$baseUrl/auth/sign_in" -Method POST -Body $loginData -ContentType "application/x-www-form-urlencoded" -UseBasicParsing
    
    if ($loginResponse.StatusCode -eq 200) {
        Write-Host "[SUCCESS] Login realizado com sucesso!" -ForegroundColor Green
        
        # Extrair cookies de sessão
        $cookies = $loginResponse.Headers["Set-Cookie"]
        Write-Host "[INFO] Cookies obtidos: $($cookies.Count) cookies" -ForegroundColor Cyan
    }
} catch {
    Write-Host "[WARNING] Login automático falhou, tentando upload direto..." -ForegroundColor Yellow
    Write-Host "[INFO] Você pode precisar fazer login manualmente primeiro" -ForegroundColor Yellow
}

# Preparar dados do upload
Write-Host "[UPLOAD] Preparando upload do sticker..." -ForegroundColor Cyan

# Ler o arquivo como bytes
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

# Adicionar cookies se disponíveis
if ($cookies) {
    $headers["Cookie"] = $cookies
}

Write-Host "[UPLOAD] Enviando sticker para a conversa..." -ForegroundColor Green

try {
    $uploadResponse = Invoke-WebRequest -Uri $uploadUrl -Method POST -Body $body -Headers $headers -UseBasicParsing
    
    if ($uploadResponse.StatusCode -eq 200 -or $uploadResponse.StatusCode -eq 201) {
        Write-Host "[SUCCESS] Sticker enviado com sucesso!" -ForegroundColor Green
        Write-Host "[INFO] Status Code: $($uploadResponse.StatusCode)" -ForegroundColor Cyan
        
        # Tentar parsear a resposta JSON
        try {
            $responseData = $uploadResponse.Content | ConvertFrom-Json
            Write-Host "[INFO] Resposta do servidor:" -ForegroundColor Cyan
            $responseData | ConvertTo-Json -Depth 3 | Write-Host
        } catch {
            Write-Host "[INFO] Resposta (texto): $($uploadResponse.Content)" -ForegroundColor Cyan
        }
        
        Write-Host ""
        Write-Host "[NEXT] Verifique a conversa em:" -ForegroundColor Green
        Write-Host "  $baseUrl/app/accounts/$AccountId/inbox/$InboxId/conversations/$ConversationId" -ForegroundColor White
        
    } else {
        Write-Host "[ERROR] Falha no upload. Status: $($uploadResponse.StatusCode)" -ForegroundColor Red
        Write-Host "[INFO] Resposta: $($uploadResponse.Content)" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "[ERROR] Erro durante o upload:" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    
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
}

Write-Host ""
Write-Host "[INFO] Alternativa: Upload via cURL" -ForegroundColor Cyan
Write-Host "curl -X POST `"$uploadUrl`" \`" -ForegroundColor White
Write-Host "  -H `"Content-Type: multipart/form-data`" \`" -ForegroundColor White
Write-Host "  -F `"message_type=incoming`" \`" -ForegroundColor White
Write-Host "  -F `"content_type=sticker`" \`" -ForegroundColor White
Write-Host "  -F `"attachments=@$StickerPath`"" -ForegroundColor White

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
