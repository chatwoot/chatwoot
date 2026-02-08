Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  TESTE DE STICKERS - GUIA DE USO" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[OBJETIVO] Testar funcionalidade de salvar stickers na biblioteca" -ForegroundColor Green
Write-Host ""

Write-Host "[SCRIPTS DISPONÍVEIS]:" -ForegroundColor Yellow
Write-Host ""

Write-Host "1. test-sticker-upload.ps1" -ForegroundColor Cyan
Write-Host "   - Upload usando PowerShell nativo" -ForegroundColor White
Write-Host "   - Mais detalhado, com tratamento de erros" -ForegroundColor White
Write-Host "   - Pode ter problemas com autenticação" -ForegroundColor White
Write-Host ""

Write-Host "2. test-sticker-curl.ps1" -ForegroundColor Cyan
Write-Host "   - Upload usando cURL" -ForegroundColor White
Write-Host "   - Mais simples e confiável" -ForegroundColor White
Write-Host "   - Requer cURL instalado" -ForegroundColor White
Write-Host ""

Write-Host "3. test-sticker-library.ps1" -ForegroundColor Cyan
Write-Host "   - Teste completo da funcionalidade" -ForegroundColor White
Write-Host "   - Envia sticker + verifica biblioteca + API" -ForegroundColor White
Write-Host "   - Recomendado para teste completo" -ForegroundColor White
Write-Host ""

Write-Host "[USO BÁSICO]:" -ForegroundColor Yellow
Write-Host ""

Write-Host "# Usar parâmetros padrão (conversa 1987)" -ForegroundColor White
Write-Host ".\test-sticker-library.ps1" -ForegroundColor Cyan
Write-Host ""

Write-Host "# Especificar conversa diferente" -ForegroundColor White
Write-Host ".\test-sticker-library.ps1 -ConversationId 1234" -ForegroundColor Cyan
Write-Host ""

Write-Host "# Usar arquivo sticker diferente" -ForegroundColor White
Write-Host ".\test-sticker-library.ps1 -StickerPath `"caminho\para\sticker.webp`"" -ForegroundColor Cyan
Write-Host ""

Write-Host "# Todos os parâmetros" -ForegroundColor White
Write-Host ".\test-sticker-library.ps1 -AccountId 3 -InboxId 4 -ConversationId 1987 -StickerPath `"public\webp-stick-test\File.webp`"" -ForegroundColor Cyan
Write-Host ""

Write-Host "[PRÉ-REQUISITOS]:" -ForegroundColor Yellow
Write-Host ""

Write-Host "1. Ambiente rodando:" -ForegroundColor White
Write-Host "   .\build-desenvolvimento.ps1 up" -ForegroundColor Cyan
Write-Host ""

Write-Host "2. Login feito no Chatwit:" -ForegroundColor White
Write-Host "   http://localhost:3000" -ForegroundColor Cyan
Write-Host "   Usuário: john@acme.inc / Senha: Password1!" -ForegroundColor Cyan
Write-Host ""

Write-Host "3. Conversa existente:" -ForegroundColor White
Write-Host "   http://localhost:3000/app/accounts/3/inbox/4/conversations/1987" -ForegroundColor Cyan
Write-Host ""

Write-Host "4. Arquivo sticker disponível:" -ForegroundColor White
Write-Host "   public\webp-stick-test\File.webp" -ForegroundColor Cyan
Write-Host ""

Write-Host "[FLUXO DE TESTE]:" -ForegroundColor Yellow
Write-Host ""

Write-Host "1. Execute o script:" -ForegroundColor White
Write-Host "   .\test-sticker-library.ps1" -ForegroundColor Cyan
Write-Host ""

Write-Host "2. Verifique a conversa:" -ForegroundColor White
Write-Host "   http://localhost:3000/app/accounts/3/inbox/4/conversations/1987" -ForegroundColor Cyan
Write-Host ""

Write-Host "3. Clique no sticker para salvar na biblioteca" -ForegroundColor White
Write-Host ""

Write-Host "4. Verifique a biblioteca:" -ForegroundColor White
Write-Host "   http://localhost:3000/app/accounts/3/stickers" -ForegroundColor Cyan
Write-Host ""

Write-Host "[TROUBLESHOOTING]:" -ForegroundColor Yellow
Write-Host ""

Write-Host "Se o upload falhar:" -ForegroundColor White
Write-Host "1. Verifique se está logado no Chatwit" -ForegroundColor Cyan
Write-Host "2. Verifique se a conversa existe" -ForegroundColor Cyan
Write-Host "3. Execute: .\build-desenvolvimento.ps1 logs" -ForegroundColor Cyan
Write-Host ""

Write-Host "Se o sticker não aparecer:" -ForegroundColor White
Write-Host "1. Verifique o formato do arquivo (deve ser WebP)" -ForegroundColor Cyan
Write-Host "2. Verifique o tamanho do arquivo" -ForegroundColor Cyan
Write-Host "3. Verifique logs do Rails" -ForegroundColor Cyan
Write-Host ""

Write-Host "Se não conseguir salvar na biblioteca:" -ForegroundColor White
Write-Host "1. Verifique se a feature está habilitada" -ForegroundColor Cyan
Write-Host "2. Verifique permissões da conta" -ForegroundColor Cyan
Write-Host "3. Verifique logs do frontend (F12)" -ForegroundColor Cyan
Write-Host ""

Write-Host "[EXEMPLO COMPLETO]:" -ForegroundColor Yellow
Write-Host ""

Write-Host "# 1. Subir ambiente" -ForegroundColor White
Write-Host ".\build-desenvolvimento.ps1 up" -ForegroundColor Cyan
Write-Host ""

Write-Host "# 2. Aguardar inicialização e fazer login" -ForegroundColor White
Write-Host "start http://localhost:3000" -ForegroundColor Cyan
Write-Host ""

Write-Host "# 3. Executar teste" -ForegroundColor White
Write-Host ".\test-sticker-library.ps1" -ForegroundColor Cyan
Write-Host ""

Write-Host "# 4. Verificar resultado" -ForegroundColor White
Write-Host "start http://localhost:3000/app/accounts/3/inbox/4/conversations/1987" -ForegroundColor Cyan
Write-Host ""

Write-Host "==========================================" -ForegroundColor Cyan
