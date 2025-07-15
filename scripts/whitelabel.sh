#!/bin/bash

echo "🎨 Iniciando processo de Whitelabel do Chatwoot..."

# Diretório do projeto
cd /Users/benevidfelixsilva/Web-Apps/chatwoot

echo ""
echo "📋 LOGOS ENCONTRADAS NO CHATWOOT:"
echo ""
echo "🔥 PRINCIPAIS (Obrigatórias):"
echo "  📁 public/brand-assets/logo.svg          → Logo principal"
echo "  📁 public/brand-assets/logo_dark.svg     → Logo modo escuro"
echo "  📁 public/brand-assets/logo_thumbnail.svg → Logo pequena"
echo "  📁 app/javascript/widget/assets/images/logo.svg → Widget chat"
echo ""
echo "🎯 SECUNDÁRIAS (Recomendadas):"
echo "  📁 app/javascript/design-system/images/logo.png"
echo "  📁 app/javascript/design-system/images/logo-dark.png"
echo "  📁 app/javascript/dashboard/assets/images/bubble-logo.svg"
echo "  📁 public/assets/images/dashboard/captain/logo.svg"
echo ""
echo "📱 FAVICONS:"
echo "  📁 public/favicon-*.png (vários tamanhos)"
echo "  📁 public/apple-icon*.png"
echo "  📁 public/android-icon*.png"

echo ""
echo "📦 Criando backup das logos originais..."
mkdir -p backups/original-logos
cp public/brand-assets/* backups/original-logos/ 2>/dev/null || true
cp app/javascript/widget/assets/images/logo.svg backups/original-logos/widget-logo.svg 2>/dev/null || true
cp app/javascript/design-system/images/* backups/original-logos/ 2>/dev/null || true

echo "✅ Backup criado em: backups/original-logos/"

echo ""
echo "📁 ESTRUTURA PARA SUAS LOGOS:"
echo "   Crie o diretório: /tmp/my-logos/"
echo "   E coloque seus arquivos:"
echo ""
echo "   📄 logo.svg          → Logo principal (200x50px)"
echo "   📄 logo_dark.svg     → Logo modo escuro (200x50px)"
echo "   📄 logo_thumbnail.svg → Ícone pequeno (32x32px)"
echo "   📄 favicon.png       → Ícone navegador (32x32px)"
echo ""

# Verificar se as logos do usuário existem
if [ -d "/tmp/my-logos" ]; then
    echo "🎉 Diretório encontrado! Substituindo logos..."
    
    # Verificar e substituir cada logo
    if [ -f "/tmp/my-logos/logo.svg" ]; then
        echo "  ✅ Substituindo logo principal..."
        cp /tmp/my-logos/logo.svg public/brand-assets/logo.svg
        cp /tmp/my-logos/logo.svg app/javascript/widget/assets/images/logo.svg
        cp /tmp/my-logos/logo.svg app/javascript/design-system/images/logo.png
    fi
    
    if [ -f "/tmp/my-logos/logo_dark.svg" ]; then
        echo "  ✅ Substituindo logo modo escuro..."
        cp /tmp/my-logos/logo_dark.svg public/brand-assets/logo_dark.svg
        cp /tmp/my-logos/logo_dark.svg app/javascript/design-system/images/logo-dark.png
    fi
    
    if [ -f "/tmp/my-logos/logo_thumbnail.svg" ]; then
        echo "  ✅ Substituindo logo thumbnail..."
        cp /tmp/my-logos/logo_thumbnail.svg public/brand-assets/logo_thumbnail.svg
        cp /tmp/my-logos/logo_thumbnail.svg app/javascript/design-system/images/logo-thumbnail.svg
    fi
    
    if [ -f "/tmp/my-logos/favicon.png" ]; then
        echo "  ✅ Substituindo favicon..."
        cp /tmp/my-logos/favicon.png public/favicon-32x32.png
        cp /tmp/my-logos/favicon.png public/favicon-96x96.png
    fi
    
    echo ""
    echo "🧹 Limpando cache..."
    rm -rf node_modules/.vite
    rm -rf public/vite
    rm -rf public/packs
    
    echo "🏗️ Recompilando..."
    bin/vite build --force
    
    echo ""
    echo "🎉 WHITELABEL CONCLUÍDO!"
    echo "   Suas logos foram aplicadas no Chatwoot!"
    
else
    echo ""
    echo "📋 PRÓXIMOS PASSOS:"
    echo ""
    echo "1️⃣ Crie o diretório:"
    echo "   mkdir -p /tmp/my-logos"
    echo ""
    echo "2️⃣ Coloque suas logos:"
    echo "   cp sua-logo.svg /tmp/my-logos/logo.svg"
    echo "   cp sua-logo-dark.svg /tmp/my-logos/logo_dark.svg"
    echo "   cp sua-logo-icon.svg /tmp/my-logos/logo_thumbnail.svg"
    echo "   cp seu-favicon.png /tmp/my-logos/favicon.png"
    echo ""
    echo "3️⃣ Execute o script novamente:"
    echo "   ./scripts/whitelabel.sh"
    echo ""
    echo "💡 DICAS:"
    echo "   • Use formato SVG quando possível"
    echo "   • Logo principal: ~200x50px"
    echo "   • Logo thumbnail: 32x32px"
    echo "   • Mantenha proporções adequadas"
fi

echo ""
echo "📚 Para mais detalhes, veja o guia completo!"
echo "🔄 Para reverter: copie arquivos de backups/original-logos/"
