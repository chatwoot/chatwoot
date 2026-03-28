#!/bin/bash
# Chatwoot Docker Setup - Setup completo em um comando!
# Uso: ./setup.sh

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}"
cat << "EOF"
   _____ _           _                      _
  / ____| |         | |                    | |
 | |    | |__   __ _| |___      _____   ___|_|
 | |    | '_ \ / _` | __\ \ /\ / / _ \ / _ \| |
 | |____| | | | (_| | |_ \ V  V / (_) | (_) | |
  \_____|_| |_|\__,_|\__| \_/\_/ \___/ \___/|_|

  Docker Development Setup
EOF
echo -e "${NC}"

log_info() {
    echo -e "${GREEN}✓${NC} $1"
}

log_step() {
    echo -e "${BLUE}➜${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Verificar pré-requisitos
check_prerequisites() {
    log_step "Verificando pré-requisitos..."

    if ! command -v docker &> /dev/null; then
        log_error "Docker não está instalado!"
        echo "Instale Docker Desktop: https://www.docker.com/products/docker-desktop"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose não está instalado!"
        exit 1
    fi

    log_info "Docker e Docker Compose encontrados"
}

# Configurar .env
setup_env() {
    log_step "Configurando variáveis de ambiente..."

    if [ -f .env ]; then
        log_warn ".env já existe. Deseja sobrescrever? (y/N)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_info "Mantendo .env existente"
            return
        fi
    fi

    # Copiar template
    cp .env.docker .env

    # Gerar SECRET_KEY_BASE
    log_step "Gerando SECRET_KEY_BASE..."
    SECRET_KEY=$(openssl rand -hex 64)

    # Substituir no .env (compatível com macOS e Linux)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/change_this_to_a_long_random_string_min_128_chars_use_openssl_rand_hex_64_to_generate_it_please_change_before_production/$SECRET_KEY/" .env
    else
        # Linux
        sed -i "s/change_this_to_a_long_random_string_min_128_chars_use_openssl_rand_hex_64_to_generate_it_please_change_before_production/$SECRET_KEY/" .env
    fi

    log_info "Arquivo .env configurado com SECRET_KEY_BASE seguro"
}

# Subir infraestrutura
start_infrastructure() {
    log_step "Iniciando serviços de infraestrutura..."

    # Subir PostgreSQL e Redis primeiro
    docker-compose up -d postgres redis mailhog

    log_info "PostgreSQL, Redis e MailHog iniciados"
    log_step "Aguardando serviços ficarem prontos (15s)..."
    sleep 15
}

# Build e subir aplicação
build_and_start_app() {
    log_step "Fazendo build da aplicação..."

    # Build sem cache para garantir versão mais recente
    docker-compose build rails vite

    log_info "Build completo"

    log_step "Iniciando aplicação..."
    docker-compose up -d rails sidekiq vite

    log_info "Rails, Sidekiq e Vite iniciados"
}

# Preparar banco de dados
setup_database() {
    log_step "Preparando banco de dados..."

    # Aguardar Rails estar pronto
    log_step "Aguardando Rails inicializar (10s)..."
    sleep 10

    # Criar banco
    log_step "Criando banco de dados..."
    docker-compose exec -T rails bundle exec rails db:create || {
        log_warn "Banco pode já existir, continuando..."
    }

    # Rodar migrations
    log_step "Executando migrations..."
    docker-compose exec -T rails bundle exec rails db:migrate

    log_info "Banco de dados configurado"

    # Perguntar sobre seed
    echo ""
    log_step "Deseja criar dados de teste? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        log_step "Criando dados de teste..."
        docker-compose exec -T rails bundle exec rails db:seed
        log_info "Dados de teste criados!"
        echo ""
        log_info "Credenciais de acesso:"
        echo "      Email: admin@chatwoot.com"
        echo "      Senha: 123456"
    fi
}

# Verificar saúde dos serviços
check_health() {
    log_step "Verificando saúde dos serviços..."

    # Verificar PostgreSQL
    if docker-compose exec -T postgres psql -U postgres -c "SELECT 1" > /dev/null 2>&1; then
        log_info "PostgreSQL: OK"
    else
        log_error "PostgreSQL: FALHOU"
    fi

    # Verificar Redis
    if docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; then
        log_info "Redis: OK"
    else
        log_error "Redis: FALHOU"
    fi

    # Verificar Rails (HTTP)
    sleep 5
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 | grep -q "200\|302"; then
        log_info "Rails: OK"
    else
        log_warn "Rails: Ainda inicializando... (isso é normal)"
    fi
}

# Mostrar resumo final
show_summary() {
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✓ Setup Completo!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${BLUE}🌐 URLs de Acesso:${NC}"
    echo "   Web App:        http://localhost:3000"
    echo "   Vite Dev:       http://localhost:3036"
    echo "   MailHog:        http://localhost:8025"
    echo ""
    echo -e "${BLUE}📊 Serviços:${NC}"
    echo "   PostgreSQL:     localhost:5432"
    echo "   Redis:          localhost:6379"
    echo ""
    echo -e "${BLUE}📝 Comandos Úteis:${NC}"
    echo "   Ver logs:       docker-compose logs -f"
    echo "   Console:        docker-compose exec rails bundle exec rails console"
    echo "   Testes:         docker-compose exec rails bundle exec rspec"
    echo "   Parar:          docker-compose down"
    echo ""
    echo -e "${BLUE}📚 Documentação:${NC}"
    echo "   Docker Guide:   ./DOCKER_QUICKSTART.md"
    echo ""
    echo -e "${YELLOW}💡 Dica:${NC} Em outra janela, execute: ${GREEN}docker-compose logs -f rails${NC}"
    echo ""
}

# Main
main() {
    echo ""
    log_step "Iniciando setup do Chatwoot..."
    echo ""

    check_prerequisites
    setup_env
    start_infrastructure
    build_and_start_app
    setup_database
    check_health
    show_summary

    # Perguntar se quer ver logs
    log_step "Deseja ver os logs agora? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        docker-compose logs -f
    fi
}

# Trap para cleanup em caso de erro
trap 'log_error "Setup falhou! Ver logs: docker-compose logs"; exit 1' ERR

# Executar
main
