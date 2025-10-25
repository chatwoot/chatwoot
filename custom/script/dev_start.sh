#!/bin/bash

# CommMate Development Mode Starter
# Runs natively on your machine with hot reload

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  CommMate Development Mode            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check prerequisites
echo -e "${BLUE}🔍 Verificando dependências...${NC}"

if ! command -v ruby &> /dev/null; then
    echo -e "${RED}❌ Ruby não encontrado!${NC}"
    echo -e "${YELLOW}Instale: brew install ruby${NC}"
    exit 1
fi
echo -e "${GREEN}  ✅ Ruby $(ruby --version | awk '{print $2}')${NC}"

if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js não encontrado!${NC}"
    echo -e "${YELLOW}Instale: brew install node${NC}"
    exit 1
fi
echo -e "${GREEN}  ✅ Node.js $(node --version)${NC}"

if ! command -v pnpm &> /dev/null; then
    echo -e "${YELLOW}⚠️  pnpm não encontrado. Instalando...${NC}"
    npm install -g pnpm
fi
echo -e "${GREEN}  ✅ pnpm $(pnpm --version)${NC}"

# Check PostgreSQL
if ! command -v psql &> /dev/null; then
    echo -e "${YELLOW}⚠️  PostgreSQL não encontrado localmente${NC}"
    echo -e "${BLUE}Iniciando PostgreSQL com Podman...${NC}"
    
    podman run -d \
      --name commmate-postgres-dev \
      -e POSTGRES_DB=chatwoot_dev \
      -e POSTGRES_USER=postgres \
      -e POSTGRES_HOST_AUTH_METHOD=trust \
      -p 5432:5432 \
      -v commmate-postgres-dev:/var/lib/postgresql/data \
      postgres:16
    
    sleep 5
    echo -e "${GREEN}  ✅ PostgreSQL iniciado (Podman)${NC}"
else
    echo -e "${GREEN}  ✅ PostgreSQL disponível${NC}"
fi

# Check Redis
if ! command -v redis-cli &> /dev/null; then
    echo -e "${YELLOW}⚠️  Redis não encontrado localmente${NC}"
    echo -e "${BLUE}Iniciando Redis com Podman...${NC}"
    
    podman run -d \
      --name commmate-redis-dev \
      -p 6379:6379 \
      redis:7-alpine
    
    sleep 3
    echo -e "${GREEN}  ✅ Redis iniciado (Podman)${NC}"
else
    echo -e "${GREEN}  ✅ Redis disponível${NC}"
fi

echo ""

# Setup environment
echo -e "${BLUE}⚙️  Configurando ambiente...${NC}"

if [ ! -f ".env" ]; then
    cp .env.development.commmate .env
    echo -e "${GREEN}  ✅ .env criado${NC}"
fi

# Install dependencies
if [ ! -d "node_modules" ]; then
    echo -e "${BLUE}📦 Instalando dependências Node.js...${NC}"
    pnpm install
fi

if [ ! -d "vendor/bundle" ] || [ ! -f "Gemfile.lock" ]; then
    echo -e "${BLUE}💎 Instalando gems Ruby...${NC}"
    bundle install
fi

echo -e "${GREEN}  ✅ Dependências instaladas${NC}"
echo ""

# Setup database
echo -e "${BLUE}🗄️  Configurando banco de dados...${NC}"
bundle exec rails db:prepare 2>/dev/null || {
    bundle exec rails db:create db:migrate
}
echo -e "${GREEN}  ✅ Banco configurado${NC}"
echo ""

# Copy CommMate assets
echo -e "${BLUE}📦 Copiando assets CommMate...${NC}"
if [ -d "custom/assets" ]; then
    mkdir -p public/images
    cp custom/assets/images/*.png public/images/ 2>/dev/null || true
    cp custom/assets/favicons/* public/ 2>/dev/null || true
    echo -e "${GREEN}  ✅ Assets copiados${NC}"
fi
echo ""

# Start development server
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ Iniciando CommMate Dev Mode!      ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}🚀 Iniciando servidores...${NC}"
echo -e "   ${YELLOW}Rails (http://localhost:3000)${NC}"
echo -e "   ${YELLOW}Vite (hot reload)${NC}"
echo ""
echo -e "${BLUE}📝 Para parar: Ctrl+C${NC}"
echo ""

# Run development server with pnpm (starts Rails + Vite)
pnpm dev

