#!/bin/bash

echo "🧹 Limpando ambiente Chatwoot..."
echo "================================="

cd /Users/benevidfelixsilva/Web-Apps/chatwoot

# 1. Para todos os processos que podem estar rodando
echo "⏹️  Parando processos existentes..."
kill -9 $(lsof -ti:3036) 2>/dev/null || echo "Porta 3036 livre"
kill -9 $(lsof -ti:3000) 2>/dev/null || echo "Porta 3000 livre"

# Remove socket do overmind se existir
rm -f ./.overmind.sock
rm -f tmp/pids/*.pid

echo "🗑️  Removendo arquivos e diretórios antigos..."

# 2. Remove node_modules e arquivos de lock
rm -rf node_modules
echo "   ✅ node_modules removido"

# 3. Remove diretórios de build/cache do Vite
rm -rf public/vite
echo "   ✅ public/vite removido"

rm -rf public/packs
echo "   ✅ public/packs removido"

# 4. Remove lockfiles (mas mantém pnpm-lock.yaml se existir)
rm -f package-lock.json
echo "   ✅ package-lock.json removido"

rm -f yarn.lock
echo "   ✅ yarn.lock removido (se existia)"

# 5. Limpa cache do pnpm
echo "🧽 Limpando cache do pnpm..."
pnpm store prune || echo "Cache do pnpm limpo"

echo ""
echo "📦 Reinstalando dependências..."
echo "==============================="

# 6. Instala dependências Ruby
echo "💎 Instalando gems Ruby..."
gem install bundler
bundle install

# 7. Instala dependências Node.js com pnpm
echo "📦 Instalando dependências Node.js com pnpm..."
pnpm install

echo ""
echo "🔧 Configuração adicional..."
echo "============================"

# 8. Atualiza browserslist
echo "🌐 Atualizando browserslist..."
npx update-browserslist-db@latest

# 9. Verifica se VIPS está instalado (necessário para processamento de imagens)
echo "🖼️  Verificando VIPS..."
if ! command -v vips &> /dev/null; then
    echo "❌ VIPS não encontrado. Instalando via Homebrew..."
    brew install vips
else
    echo "✅ VIPS já instalado"
fi

echo ""
echo "✅ Limpeza e reinstalação concluída!"
echo "===================================="
echo ""
echo "🚀 Para iniciar o projeto, use um dos comandos:"
echo "   make run          (usa overmind - recomendado)"
echo "   make force_run    (força nova instância)"
echo "   foreman start -f Procfile.dev"
echo ""
echo "🔍 Para debug:"
echo "   make debug        (conecta ao backend)"
echo "   make debug_worker (conecta ao worker)"
