#!/usr/bin/env pwsh

# Script para testar o payload expandido do Dialogflow
# Uso: .\debug-dialogflow.ps1

Write-Host "🔍 DEBUG PAYLOAD DIALOGFLOW EXPANDIDO" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

# Verifica se estamos no diretório correto
if (!(Test-Path "app/models")) {
    Write-Host "❌ Execute este script na raiz do projeto Chatwoot" -ForegroundColor Red
    exit 1
}

# Verifica se Docker está rodando
Write-Host "🐳 Verificando Docker..." -ForegroundColor Yellow
try {
    $dockerStatus = docker ps --format "table {{.Names}}\t{{.Status}}" | Select-String "rails-1|sidekiq-1"
    if ($dockerStatus) {
        Write-Host "✅ Docker containers ativos:" -ForegroundColor Green
        $dockerStatus | ForEach-Object { Write-Host "   $_" -ForegroundColor Green }
    } else {
        Write-Host "❌ Containers não encontrados. Execute: docker-compose up -d" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Docker não está rodando ou não instalado" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🧪 Executando debug do payload expandido..." -ForegroundColor Yellow

# Executa a task de debug
try {
    docker exec -it rails-1 bundle exec rake debug:dialogflow_payload
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Debug executado com sucesso!" -ForegroundColor Green
        Write-Host ""
        Write-Host "💡 PRÓXIMOS PASSOS:" -ForegroundColor Cyan
        Write-Host "1. Analise os campos do payload expandido acima" -ForegroundColor White
        Write-Host "2. Configure seu webhook Dialogflow para usar:" -ForegroundColor White
        Write-Host "   - req.body.queryParams.payload.status_typebot" -ForegroundColor Yellow
        Write-Host "   - req.body.queryParams.payload.contact_name" -ForegroundColor Yellow
        Write-Host "   - req.body.queryParams.payload.conversation_status" -ForegroundColor Yellow
        Write-Host "   - req.body.queryParams.payload.is_business_hours" -ForegroundColor Yellow
        Write-Host "   - req.body.queryParams.payload.high_priority" -ForegroundColor Yellow
        Write-Host "3. Teste enviando uma mensagem no WhatsApp" -ForegroundColor White
        Write-Host "4. Verifique os logs com: docker logs rails-1 -f" -ForegroundColor White
        Write-Host ""
        Write-Host "📋 EXEMPLO DE USO NO WEBHOOK:" -ForegroundColor Cyan
        Write-Host "const payload = req.body.queryParams?.payload;" -ForegroundColor Yellow
        Write-Host "const statusTypebot = payload?.status_typebot;" -ForegroundColor Yellow
        Write-Host "const isBusinessHours = payload?.is_business_hours;" -ForegroundColor Yellow
        Write-Host "const isHighPriority = payload?.high_priority;" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "if (statusTypebot === 'Ligado') {" -ForegroundColor Yellow
        Write-Host "  // Lógica para typebot ligado" -ForegroundColor Yellow
        Write-Host "  return { fulfillmentText: 'Typebot está ativo!' };" -ForegroundColor Yellow
        Write-Host "}" -ForegroundColor Yellow
        
    } else {
        Write-Host "❌ Erro ao executar debug" -ForegroundColor Red
    }
    
} catch {
    Write-Host "❌ Erro ao executar comando: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎯 Para testar em tempo real:" -ForegroundColor Cyan
Write-Host "docker logs rails-1 -f | Select-String 'SOCIALWISE'" -ForegroundColor Yellow
Write-Host ""
Write-Host "🔚 Debug concluído!" -ForegroundColor Green 