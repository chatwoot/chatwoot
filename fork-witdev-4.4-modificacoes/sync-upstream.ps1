#!/usr/bin/env pwsh

Write-Host "🔄 Sincronizando com Chatwoot upstream..." -ForegroundColor Green

# Verificar se upstream existe
$upstreamExists = git remote | Where-Object { $_ -eq "upstream" }
if (-not $upstreamExists) {
    Write-Host "📡 Adicionando upstream..." -ForegroundColor Yellow
    git remote add upstream https://github.com/chatwoot/chatwoot.git
}

# Buscar atualizações
Write-Host "📥 Buscando atualizações..." -ForegroundColor Blue
git fetch upstream

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Falha ao buscar atualizações!" -ForegroundColor Red
    exit 1
}

# Salvar branch atual
$currentBranch = git branch --show-current
Write-Host "💾 Branch atual: $currentBranch" -ForegroundColor Cyan

# Ir para develop
Write-Host "🔄 Mudando para develop..." -ForegroundColor Blue
git checkout develop

# Verificar se há mudanças locais
$hasChanges = git status --porcelain
if ($hasChanges) {
    Write-Host "⚠️  Há mudanças não commitadas em develop:" -ForegroundColor Yellow
    Write-Host $hasChanges -ForegroundColor Yellow
    $continue = Read-Host "Continuar mesmo assim? (y/N)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        git checkout $currentBranch
        Write-Host "❌ Sincronização cancelada" -ForegroundColor Red
        exit 1
    }
}

# Merge das atualizações
Write-Host "🔀 Aplicando atualizações..." -ForegroundColor Blue
git merge upstream/develop

if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Conflitos de merge detectados!" -ForegroundColor Yellow
    Write-Host "📋 Resolva os conflitos manualmente:" -ForegroundColor Yellow
    Write-Host "   1. git status                    # Ver conflitos" -ForegroundColor White
    Write-Host "   2. Editar arquivos em conflito   # Resolver manualmente" -ForegroundColor White
    Write-Host "   3. git add <arquivo>             # Adicionar resolvidos" -ForegroundColor White
    Write-Host "   4. git commit                    # Finalizar merge" -ForegroundColor White
    exit 1
}

# Voltar para branch pessoal se não era develop
if ($currentBranch -ne "develop") {
    Write-Host "🔄 Voltando para $currentBranch..." -ForegroundColor Blue
    git checkout $currentBranch
    
    Write-Host "🔀 Aplicando atualizações na sua branch..." -ForegroundColor Blue
    git merge develop
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️  Conflitos na sua branch!" -ForegroundColor Yellow
        Write-Host "📋 Resolva manualmente ou use:" -ForegroundColor Yellow
        Write-Host "   git merge --abort    # Para cancelar o merge" -ForegroundColor White
        exit 1
    }
}

# Resumo
Write-Host "`n🎉 Sincronização concluída!" -ForegroundColor Green
Write-Host "📊 Resumo das mudanças:" -ForegroundColor Cyan
git log --oneline upstream/develop..HEAD~1 | head -5

Write-Host "`n✅ Próximos passos:" -ForegroundColor Yellow
Write-Host "   1. Testar as mudanças localmente" -ForegroundColor White
Write-Host "   2. Fazer push das atualizações:" -ForegroundColor White
Write-Host "      git push origin $currentBranch" -ForegroundColor Gray
Write-Host "   3. Rebuild da imagem Docker:" -ForegroundColor White
Write-Host "      .\build-and-push.ps1 -Version 'v4.3.3' -Enterprise -Push -Latest" -ForegroundColor Gray 