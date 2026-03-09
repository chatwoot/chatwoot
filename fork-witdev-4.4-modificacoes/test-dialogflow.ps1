Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "  TESTE DIALOGFLOW - SIMULACAO WHATSAPP" -ForegroundColor Cyan  
Write-Host "===========================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "Executando teste Dialogflow no container..." -ForegroundColor Blue

# Executa o rake task no container Rails
docker-compose -f docker-compose.yaml -p chatwit-dev exec rails bundle exec rake test:dialogflow

Write-Host ""
Write-Host "Teste concluido!" -ForegroundColor Green
Write-Host "Verifique os logs acima para detalhes do processamento" -ForegroundColor Yellow

# Opcao para ver logs em tempo real
Write-Host ""
$response = Read-Host "Deseja ver os logs do Sidekiq em tempo real? (y/n)"

if ($response -eq "y" -or $response -eq "Y") 
{
    Write-Host "Mostrando logs do Sidekiq (Ctrl+C para sair)..." -ForegroundColor Blue
    docker-compose -f docker-compose.yaml -p chatwit-dev logs -f sidekiq
}

Write-Host ""
Write-Host "Script finalizado!" -ForegroundColor Green 