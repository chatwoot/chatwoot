#!/bin/bash

# CommMate Local Test Runner (Simplified)
# Uses official Chatwoot image + mounts customizations

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  CommMate Local Test (Rápido!)        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Detect container runtime
if command -v podman-compose &> /dev/null; then
    COMPOSE_CMD="podman-compose"
    echo -e "${GREEN}✅ Usando Podman${NC}"
elif command -v podman &> /dev/null && command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
    export DOCKER_HOST="unix:///run/user/$(id -u)/podman/podman.sock"
    echo -e "${GREEN}✅ Usando Podman com docker-compose${NC}"
elif command -v docker &> /dev/null; then
    if docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
    else
        COMPOSE_CMD="docker-compose"
    fi
    echo -e "${GREEN}✅ Usando Docker${NC}"
else
    echo -e "${RED}❌ Erro: Nem Podman nem Docker encontrados!${NC}"
    exit 1
fi
echo ""

# Check if .env.commmate exists
if [ ! -f ".env.commmate" ]; then
    echo -e "${YELLOW}⚠️  Criando .env.commmate...${NC}"
    cat > .env.commmate << 'ENVEOF'
# CommMate Local Config
APP_NAME=CommMate
BRAND_NAME=CommMate
INSTALLATION_ENV=docker
RAILS_ENV=production
NODE_ENV=production
POSTGRES_HOST=postgres
POSTGRES_DATABASE=chatwoot
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=
REDIS_URL=redis://redis:6379
REDIS_PASSWORD=
SECRET_KEY_BASE=replace_with_lengthy_secure_hex_minimum_128_chars_long_for_security_purposes_generate_with_rails_secret_command
FRONTEND_URL=http://localhost:3000
ENABLE_ACCOUNT_SIGNUP=true
HIDE_BRANDING=true
DEFAULT_LOCALE=pt_BR
SMTP_ADDRESS=mailhog
SMTP_PORT=1025
SMTP_DOMAIN=localhost
MAILER_SENDER_EMAIL=noreply@commmate.local
ACTIVE_STORAGE_SERVICE=local
ENVEOF
    echo -e "${GREEN}✅ .env.commmate criado${NC}"
fi

# Create symlink
if [ ! -f ".env" ] || [ ! -L ".env" ]; then
    ln -sf .env.commmate .env
    echo -e "${GREEN}✅ Symlink criado${NC}"
fi
echo ""

# Copy assets
echo -e "${BLUE}📦 Copiando assets CommMate...${NC}"
mkdir -p public/images
mkdir -p public/commmate

# Copy logos
if [ -f "custom/assets/images/logo-full.png" ]; then
    cp custom/assets/images/*.png public/images/ 2>/dev/null || true
    echo -e "${GREEN}  ✅ Logos copiados${NC}"
fi

# Copy favicons
if [ -f "custom/assets/favicons/favicon.ico" ]; then
    cp custom/assets/favicons/* public/ 2>/dev/null || true
    echo -e "${GREEN}  ✅ Favicons copiados${NC}"
fi
echo ""

# Pull images first
echo -e "${BLUE}📥 Baixando imagens Docker...${NC}"
$COMPOSE_CMD -f docker-compose.local.yaml pull
echo ""

# Stop any running instances
if $COMPOSE_CMD -f docker-compose.local.yaml ps 2>/dev/null | grep -q "Up"; then
    echo -e "${YELLOW}⚠️  Parando serviços antigos...${NC}"
    $COMPOSE_CMD -f docker-compose.local.yaml down
fi

# Start services
echo -e "${BLUE}🚀 Iniciando CommMate...${NC}"
$COMPOSE_CMD -f docker-compose.local.yaml up -d

# Wait for services
echo -e "${YELLOW}⏳ Aguardando serviços (45s)...${NC}"
sleep 45

# Setup database
echo -e "${BLUE}🗄️  Configurando banco de dados...${NC}"
$COMPOSE_CMD -f docker-compose.local.yaml exec -T rails bundle exec rails db:prepare 2>/dev/null || {
    echo -e "${YELLOW}  Criando banco...${NC}"
    $COMPOSE_CMD -f docker-compose.local.yaml exec -T rails bundle exec rails db:create
    $COMPOSE_CMD -f docker-compose.local.yaml exec -T rails bundle exec rails db:migrate
}
echo -e "${GREEN}✅ Banco configurado${NC}"
echo ""

# Success
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ CommMate Rodando!                 ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📍 URLs:${NC}"
echo -e "   🌐 CommMate:  ${YELLOW}http://localhost:3000${NC}"
echo -e "   📧 MailHog:   ${YELLOW}http://localhost:8025${NC}"
echo ""
echo -e "${BLUE}👤 Criar conta admin:${NC}"
echo -e "   ${YELLOW}http://localhost:3000/auth/signup${NC}"
echo ""
echo -e "${BLUE}📋 Comandos úteis:${NC}"
echo -e "   Ver logs:      ${YELLOW}$COMPOSE_CMD -f docker-compose.local.yaml logs -f${NC}"
echo -e "   Console:       ${YELLOW}$COMPOSE_CMD -f docker-compose.local.yaml exec rails rails console${NC}"
echo -e "   Parar:         ${YELLOW}$COMPOSE_CMD -f docker-compose.local.yaml down${NC}"
echo -e "   Rebuild:       ${YELLOW}$COMPOSE_CMD -f docker-compose.local.yaml up --pull always${NC}"
echo ""
echo -e "${GREEN}🎉 CommMate pronto! Acesse http://localhost:3000${NC}"

