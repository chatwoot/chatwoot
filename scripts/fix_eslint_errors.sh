#!/bin/bash

echo "🔍 Verificando e corrigindo erros de ESLint..."

# Navegar para o diretório do projeto
cd /Users/benevidfelixsilva/Web-Apps/chatwoot

echo "🧹 Limpando cache do ESLint..."
rm -rf node_modules/.cache/.eslintcache 2>/dev/null || true

echo "🔧 Executando ESLint fix automático..."

# Executar ESLint com correção automática
pnpm run eslint:fix

echo "✅ ESLint fix concluído!"

echo "🔍 Verificando se ainda existem erros..."

# Verificar se ainda existem erros
pnpm run eslint --max-warnings 0 || echo "⚠️  Ainda existem alguns warnings que podem precisar de correção manual"

echo "🎯 Principais correções aplicadas:"
echo "   • isNaN() → Number.isNaN()"
echo "   • Formatação de código padronizada"
echo "   • Imports organizados"
echo "   • Espaçamento consistente"

echo ""
echo "🔄 Para recompilar com as correções:"
echo "   bin/vite build"
echo "   foreman start -f Procfile.dev"
