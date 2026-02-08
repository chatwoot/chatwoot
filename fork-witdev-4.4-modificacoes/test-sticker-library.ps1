param(
    [string]$ConversationId = "1987",
    [string]$AccountId = "3",
    [string]$InboxId = "4",
    [string]$StickerPath = "public\webp-stick-test\File.webp"
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  TESTE DE BIBLIOTECA DE STICKERS" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se o arquivo existe
if (-not (Test-Path $StickerPath)) {
    Write-Host "[ERROR] Arquivo sticker nao encontrado: $StickerPath" -ForegroundColor Red
    exit 1
}

# Verificar se o ambiente está rodando (versão melhorada)
Write-Host "[INFO] Verificando se o ambiente está rodando..." -ForegroundColor Cyan

# Verificar containers Docker primeiro
try {
    $containers = docker ps --format "table {{.Names}}\t{{.Status}}" 2>$null | Select-String "chatwit-dev-rails-1"
    
    if ($containers) {
        Write-Host "[SUCCESS] Container Rails encontrado!" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Container Rails não encontrado!" -ForegroundColor Red
        Write-Host "[INFO] Execute: .\build-desenvolvimento.ps1 up" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "[WARNING] Não foi possível verificar containers Docker" -ForegroundColor Yellow
}

# Verificar se a porta 3000 está respondendo (com timeout)
Write-Host "[INFO] Verificando se a aplicação está respondendo..." -ForegroundColor Cyan

try {
    # Usar Test-NetConnection com timeout
    $connection = Test-NetConnection -ComputerName "localhost" -Port 3000 -InformationLevel Quiet -WarningAction SilentlyContinue
    
    if ($connection) {
        Write-Host "[SUCCESS] Aplicação respondendo na porta 3000!" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Aplicação não está respondendo na porta 3000" -ForegroundColor Red
        Write-Host "[INFO] Aguarde mais alguns segundos ou execute: .\build-desenvolvimento.ps1 up" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "[WARNING] Não foi possível testar conexão com a aplicação" -ForegroundColor Yellow
    Write-Host "[INFO] Continuando mesmo assim..." -ForegroundColor Cyan
}

$baseUrl = "http://localhost:3000"

Write-Host ""
Write-Host "[STEP 1] Enviando sticker para a conversa..." -ForegroundColor Green

# Primeiro, enviar o sticker
$uploadUrl = "$baseUrl/app/accounts/$AccountId/inbox/$InboxId/conversations/$ConversationId/messages"

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

# Comando cURL para upload
$curlCmd = @(
    "curl",
    "-X", "POST",
    "`"$uploadUrl`"",
    "-H", "`"Content-Type: multipart/form-data`"",
    "-H", "`"Accept: application/json`"",
    "-F", "`"message_type=incoming`"",
    "-F", "`"content_type=sticker`"",
    "-F", "`"attachments=@$StickerPath`"",
    "-s",  # Silent mode
    "--max-time", "30"  # Timeout de 30 segundos
) -join " "

Write-Host "[INFO] Executando upload..." -ForegroundColor Cyan
Write-Host "[CMD] $curlCmd" -ForegroundColor Yellow

try {
    $uploadResult = Invoke-Expression $curlCmd
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SUCCESS] Sticker enviado!" -ForegroundColor Green
        
        # Tentar extrair o ID da mensagem da resposta
        try {
            $responseData = $uploadResult | ConvertFrom-Json
            $messageId = $responseData.id
            Write-Host "[INFO] ID da mensagem: $messageId" -ForegroundColor Cyan
        } catch {
            Write-Host "[INFO] Não foi possível extrair ID da mensagem" -ForegroundColor Yellow
            Write-Host "[INFO] Resposta: $uploadResult" -ForegroundColor Cyan
        }
        
    } else {
        Write-Host "[ERROR] Falha ao enviar sticker" -ForegroundColor Red
        Write-Host "[INFO] Resposta: $uploadResult" -ForegroundColor Yellow
        Write-Host "[INFO] Verifique se está logado no Chatwit primeiro" -ForegroundColor Yellow
        exit 1
    }
    
} catch {
    Write-Host "[ERROR] Erro durante upload: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[STEP 2] Verificando biblioteca de stickers..." -ForegroundColor Green

# URL da biblioteca de stickers
$libraryUrl = "$baseUrl/app/accounts/$AccountId/stickers"

Write-Host "[INFO] URL da biblioteca: $libraryUrl" -ForegroundColor Cyan

# Tentar acessar a biblioteca com timeout
try {
    $libraryResponse = Invoke-WebRequest -Uri $libraryUrl -UseBasicParsing -TimeoutSec 10 -ErrorAction SilentlyContinue
    
    if ($libraryResponse) {
        Write-Host "[SUCCESS] Biblioteca acessível!" -ForegroundColor Green
        Write-Host "[INFO] Status: $($libraryResponse.StatusCode)" -ForegroundColor Cyan
    } else {
        Write-Host "[WARNING] Biblioteca não acessível via web request" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "[WARNING] Erro ao acessar biblioteca: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[STEP 3] Verificando API de stickers..." -ForegroundColor Green

# API de stickers
$apiUrl = "$baseUrl/api/v1/accounts/$AccountId/stickers"

Write-Host "[INFO] API URL: $apiUrl" -ForegroundColor Cyan

try {
    $apiResponse = Invoke-WebRequest -Uri $apiUrl -UseBasicParsing -TimeoutSec 10 -ErrorAction SilentlyContinue
    
    if ($apiResponse -and $apiResponse.StatusCode -eq 200) {
        Write-Host "[SUCCESS] API de stickers acessível!" -ForegroundColor Green
        
        try {
            $stickers = $apiResponse.Content | ConvertFrom-Json
            Write-Host "[INFO] Stickers na biblioteca: $($stickers.Count)" -ForegroundColor Cyan
            
            if ($stickers.Count -gt 0) {
                Write-Host "[INFO] Últimos stickers:" -ForegroundColor Cyan
                $stickers | Select-Object -First 3 | ForEach-Object {
                    Write-Host "  - $($_.name) ($($_.file_type))" -ForegroundColor White
                }
            }
            
        } catch {
            Write-Host "[INFO] Resposta da API: $($apiResponse.Content)" -ForegroundColor Yellow
        }
        
    } else {
        Write-Host "[WARNING] API não acessível ou retornou erro" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "[WARNING] Erro ao acessar API: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[STEP 4] Verificando conversa para sticker recebido..." -ForegroundColor Green

# Verificar mensagens da conversa
$messagesUrl = "$baseUrl/api/v1/accounts/$AccountId/conversations/$ConversationId/messages"

Write-Host "[INFO] Verificando mensagens da conversa..." -ForegroundColor Cyan

try {
    $messagesResponse = Invoke-WebRequest -Uri $messagesUrl -UseBasicParsing -TimeoutSec 10 -ErrorAction SilentlyContinue
    
    if ($messagesResponse -and $messagesResponse.StatusCode -eq 200) {
        Write-Host "[SUCCESS] Mensagens acessíveis!" -ForegroundColor Green
        
        try {
            $messages = $messagesResponse.Content | ConvertFrom-Json
            $stickerMessages = $messages.payload | Where-Object { $_.content_type -eq "sticker" }
            
            Write-Host "[INFO] Mensagens de sticker encontradas: $($stickerMessages.Count)" -ForegroundColor Cyan
            
            if ($stickerMessages.Count -gt 0) {
                $latestSticker = $stickerMessages | Sort-Object created_at -Descending | Select-Object -First 1
                Write-Host "[INFO] Último sticker:" -ForegroundColor Cyan
                Write-Host "  ID: $($latestSticker.id)" -ForegroundColor White
                Write-Host "  Tipo: $($latestSticker.content_type)" -ForegroundColor White
                Write-Host "  Criado: $($latestSticker.created_at)" -ForegroundColor White
                
                if ($latestSticker.attachments) {
                    Write-Host "  Anexos: $($latestSticker.attachments.Count)" -ForegroundColor White
                    $latestSticker.attachments | ForEach-Object {
                        Write-Host "    - $($_.file_type): $($_.file_name)" -ForegroundColor White
                    }
                }
            }
            
        } catch {
            Write-Host "[INFO] Resposta das mensagens: $($messagesResponse.Content)" -ForegroundColor Yellow
        }
        
    } else {
        Write-Host "[WARNING] Mensagens não acessíveis" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "[WARNING] Erro ao acessar mensagens: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[NEXT] Próximos passos para testar:" -ForegroundColor Green
Write-Host "  1. Acesse a conversa: $baseUrl/app/accounts/$AccountId/inbox/$InboxId/conversations/$ConversationId" -ForegroundColor White
Write-Host "  2. Verifique se o sticker aparece na conversa" -ForegroundColor White
Write-Host "  3. Clique no sticker para salvar na biblioteca" -ForegroundColor White
Write-Host "  4. Acesse a biblioteca: $baseUrl/app/accounts/$AccountId/stickers" -ForegroundColor White
Write-Host "  5. Verifique se o sticker foi salvo" -ForegroundColor White

Write-Host ""
Write-Host "[DEBUG] Para ver logs do Rails:" -ForegroundColor Cyan
Write-Host "  .\build-desenvolvimento.ps1 logs" -ForegroundColor White

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
