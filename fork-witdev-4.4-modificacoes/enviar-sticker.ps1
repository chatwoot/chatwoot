# Script simples para enviar sticker
$baseUrl = "http://localhost:3000"
$uploadUrl = "$baseUrl/api/v1/accounts/3/conversations/1987/messages"
$stickerPath = "public\webp-stick-test\File.webp"

Write-Host "Enviando sticker..." -ForegroundColor Green

# Comando cURL direto (usando caminho completo)
$result = & "C:\Windows\System32\curl.exe" -X POST $uploadUrl -H "Content-Type: multipart/form-data" -F "message_type=incoming" -F "content_type=sticker" -F "attachments=@$stickerPath"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Sticker enviado!" -ForegroundColor Green
    Start-Process "$baseUrl/app/accounts/3/inbox/4/conversations/1987"
} else {
    Write-Host "❌ Erro: $result" -ForegroundColor Red
}
