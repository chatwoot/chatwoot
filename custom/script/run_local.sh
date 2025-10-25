#!/bin/bash

# CommMate Local Test Runner
# Automated script to run CommMate locally for testing

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  CommMate Local Test (Podman)         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Detect container runtime (podman or docker)
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
    echo -e "${YELLOW}Instale um deles:${NC}"
    echo -e "  Podman: brew install podman podman-compose"
    echo -e "  Docker: brew install docker"
    exit 1
fi

echo ""

# Check if .env.commmate exists
if [ ! -f ".env.commmate" ]; then
    echo -e "${YELLOW}⚠️  .env.commmate não encontrado. Criando...${NC}"
    cat > .env.commmate << 'ENVEOF'
APP_NAME=CommMate
BRAND_NAME=CommMate
RAILS_ENV=development
NODE_ENV=development
POSTGRES_HOST=postgres
POSTGRES_DATABASE=chatwoot
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=
REDIS_URL=redis://redis:6379
REDIS_PASSWORD=
SECRET_KEY_BASE=replace_with_lengthy_secure_hex
FRONTEND_URL=http://localhost:3000
ENABLE_ACCOUNT_SIGNUP=true
HIDE_BRANDING=true
DEFAULT_LOCALE=pt_BR
VITE_DEV_SERVER_HOST=vite
SMTP_ADDRESS=mailhog
SMTP_PORT=1025
RAILS_LOG_TO_STDOUT=true
ENVEOF
    echo -e "${GREEN}✅ .env.commmate criado${NC}"
    echo ""
fi

# Create symlink to .env if needed
if [ ! -f ".env" ]; then
    ln -s .env.commmate .env
    echo -e "${GREEN}✅ Symlink .env → .env.commmate criado${NC}"
fi

# Copy CommMate assets
echo -e "${BLUE}📦 Copiando assets CommMate...${NC}"
if [ -f "script/copy_commmate_assets.sh" ]; then
    chmod +x script/copy_commmate_assets.sh
    ./script/copy_commmate_assets.sh
else
    echo -e "${YELLOW}⚠️  Script de assets não encontrado${NC}"
fi
echo ""

# Check if services are running
if $COMPOSE_CMD ps 2>/dev/null | grep -q "Up"; then
    echo -e "${YELLOW}⚠️  Serviços já estão rodando. Reiniciando...${NC}"
    $COMPOSE_CMD down
fi

# Start services
echo -e "${BLUE}🚀 Iniciando serviços com $COMPOSE_CMD...${NC}"
$COMPOSE_CMD up -d

# Wait for services
echo -e "${YELLOW}⏳ Aguardando serviços iniciarem (30s)...${NC}"
sleep 30

# Check if database exists
DB_EXISTS=$($COMPOSE_CMD exec -T postgres psql -U postgres -lqt 2>/dev/null | cut -d \| -f 1 | grep -w chatwoot | wc -l || echo "0")

if [ "$DB_EXISTS" -eq "0" ]; then
    echo -e "${BLUE}🗄️  Criando banco de dados...${NC}"
    $COMPOSE_CMD exec -T rails bundle exec rails db:create
    echo -e "${GREEN}✅ Banco criado${NC}"
fi

# Run migrations
echo -e "${BLUE}🔄 Rodando migrations...${NC}"
$COMPOSE_CMD exec -T rails bundle exec rails db:migrate
echo -e "${GREEN}✅ Migrations concluídas${NC}"
echo ""

# Check if we should seed
read -p "$(echo -e ${YELLOW}Deseja popular o banco com dados de exemplo? [y/N]: ${NC})" -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}🌱 Populando banco...${NC}"
    $COMPOSE_CMD exec -T rails bundle exec rails db:seed
    echo -e "${GREEN}✅ Dados de exemplo criados${NC}"
fi
echo ""

# Success message
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ CommMate Rodando!                 ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📍 URLs:${NC}"
echo -e "   🌐 Aplicação:  ${YELLOW}http://localhost:3000${NC}"
echo -e "   📧 MailHog:    ${YELLOW}http://localhost:8025${NC}"
echo ""
echo -e "${BLUE}👤 Criar usuário admin:${NC}"
echo -e "   ${YELLOW}http://localhost:3000/auth/signup${NC}"
echo ""
echo -e "${BLUE}📋 Comandos úteis:${NC}"
echo -e "   Ver logs:      ${YELLOW}$COMPOSE_CMD logs -f${NC}"
echo -e "   Console Rails: ${YELLOW}$COMPOSE_CMD exec rails bundle exec rails console${NC}"
echo -e "   Parar tudo:    ${YELLOW}$COMPOSE_CMD down${NC}"
echo ""
echo -e "${GREEN}🎉 Acesse http://localhost:3000 e teste seu CommMate!${NC}"

