#!/usr/bin/env pwsh

Write-Host "🔧 Configurando Hook do Socialwise..." -ForegroundColor Cyan

# Executar a rake task
try {
    Write-Host "▶️  Executando rake socialwise:setup..." -ForegroundColor Yellow
    
    # Usar Docker para executar a rake task
    docker-compose exec rails bundle exec rake socialwise:setup ACCOUNT_ID=2
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Hook do Socialwise configurado com sucesso!" -ForegroundColor Green
        Write-Host ""
        Write-Host "📋 Próximo passo: Teste o sistema enviando 'exibirpayload' novamente" -ForegroundColor Yellow
    } else {
        Write-Host "❌ Erro ao configurar o hook do Socialwise" -ForegroundColor Red
    }
}
catch {
    Write-Host "❌ Erro ao executar o comando: $($_.Exception.Message)" -ForegroundColor Red
} 