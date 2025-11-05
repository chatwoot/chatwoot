#!/bin/bash
# Script completo de setup do Chatwoot com PM2
# Este script configura tudo automaticamente: dependências, PostgreSQL, Redis e banco de dados

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Chatwoot Setup - Configuração Completa                  ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Função para verificar se comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 1. Verificar dependências
echo -e "${BLUE}[1/7]${NC} Verificando dependências..."
if ! command_exists bundle; then
    echo -e "${RED}❌ Bundler não encontrado. Instale Ruby e Bundler primeiro.${NC}"
    exit 1
fi
if ! command_exists pnpm; then
    echo -e "${RED}❌ pnpm não encontrado. Instale com: npm install -g pnpm${NC}"
    exit 1
fi
if ! command_exists pm2; then
    echo -e "${RED}❌ PM2 não encontrado. Instale com: npm install -g pm2${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Dependências encontradas"

# 2. Instalar dependências Ruby e Node (se necessário)
echo -e "\n${BLUE}[2/7]${NC} Verificando dependências do projeto..."
if ! bundle check >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠ Instalando gems Ruby...${NC}"
    bundle install --path vendor/bundle
fi
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}⚠ Instalando pacotes Node.js...${NC}"
    pnpm install
fi
echo -e "${GREEN}✓${NC} Dependências do projeto OK"

# 3. Verificar e configurar PostgreSQL
echo -e "\n${BLUE}[3/7]${NC} Configurando PostgreSQL..."
if ! pg_isready -h localhost >/dev/null 2>&1; then
    echo -e "${RED}❌ PostgreSQL não está rodando.${NC}"
    echo "   Execute: sudo systemctl start postgresql"
    exit 1
fi

# Verificar/criar .env
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠ Criando arquivo .env a partir do .env.example...${NC}"
    cp .env.example .env
    # Gerar SECRET_KEY_BASE
    if command_exists bundle; then
        SECRET=$(bundle exec rake secret 2>/dev/null || head /dev/urandom | tr -dc A-Za-z0-9 | head -c 63)
    else
        SECRET=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 63)
    fi
    sed -i "s/^SECRET_KEY_BASE=.*/SECRET_KEY_BASE=$SECRET/" .env
fi

# Corrigir configurações no .env
sed -i 's|^POSTGRES_HOST=postgres|POSTGRES_HOST=localhost|' .env 2>/dev/null || true
sed -i 's|^REDIS_URL=redis://redis:|REDIS_URL=redis://127.0.0.1:|' .env 2>/dev/null || true

# Verificar senha do PostgreSQL
POSTGRES_PASS=$(grep "^POSTGRES_PASSWORD=" .env | cut -d'=' -f2 || echo "")
if [ -n "$POSTGRES_PASS" ]; then
    if ! PGPASSWORD="$POSTGRES_PASS" psql -h localhost -U postgres -d postgres -c "SELECT 1;" >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠ Senha do PostgreSQL não está correta.${NC}"
        echo "   Configure manualmente:"
        echo "   sudo -u postgres psql -c \"ALTER USER postgres PASSWORD '$POSTGRES_PASS';\""
        echo ""
        read -p "   Pressione Enter após configurar a senha, ou Ctrl+C para cancelar..."
    fi
fi
echo -e "${GREEN}✓${NC} PostgreSQL configurado"

# 4. Verificar e configurar Redis
echo -e "\n${BLUE}[4/7]${NC} Configurando Redis..."
if ! command_exists redis-server; then
    echo -e "${YELLOW}⚠ Redis não encontrado.${NC}"
    echo "   Instale com: sudo apt install redis-server"
    echo "   Depois execute: sudo systemctl start redis-server"
    read -p "   Pressione Enter após instalar/iniciar Redis, ou Ctrl+C para cancelar..."
fi

if ! redis-cli ping >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠ Redis não está rodando.${NC}"
    echo "   Execute: sudo systemctl start redis-server"
    read -p "   Pressione Enter após iniciar Redis, ou Ctrl+C para cancelar..."
fi
echo -e "${GREEN}✓${NC} Redis configurado"

# 5. Criar e migrar banco de dados
echo -e "\n${BLUE}[5/7]${NC} Configurando banco de dados..."
if bundle exec rails db:chatwoot_prepare; then
    echo -e "${GREEN}✓${NC} Banco de dados criado e migrado"
else
    echo -e "${RED}❌ Erro ao configurar banco de dados${NC}"
    echo ""
    echo "Possíveis causas:"
    echo "1. Senha do PostgreSQL incorreta - verifique POSTGRES_PASSWORD no .env"
    echo "2. PostgreSQL não está acessível"
    echo ""
    exit 1
fi

# 6. Verificar scripts PM2
echo -e "\n${BLUE}[6/7]${NC} Verificando scripts PM2..."
if [ ! -f "bin/pm2-web.sh" ] || [ ! -f "bin/pm2-worker.sh" ]; then
    echo -e "${RED}❌ Scripts PM2 não encontrados${NC}"
    exit 1
fi
chmod +x bin/pm2-web.sh bin/pm2-worker.sh 2>/dev/null || true
echo -e "${GREEN}✓${NC} Scripts PM2 OK"

# 7. Status final
echo -e "\n${BLUE}[7/7]${NC} Verificando status..."
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ Setup Completo!                                      ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Próximos passos:${NC}"
echo ""
echo "1. Iniciar o Chatwoot com PM2:"
echo -e "   ${YELLOW}pm2 start ecosystem.config.js${NC}"
echo ""
echo "2. Verificar status:"
echo -e "   ${YELLOW}pm2 status${NC}"
echo ""
echo "3. Ver logs:"
echo -e "   ${YELLOW}pm2 logs${NC}"
echo ""
echo "4. Acessar no navegador:"
echo -e "   ${YELLOW}http://localhost:3000${NC}"
echo ""
echo -e "${GREEN}Configurações salvas em: .env${NC}"
echo -e "${GREEN}PM2 configurado em: ecosystem.config.js${NC}"
echo ""

