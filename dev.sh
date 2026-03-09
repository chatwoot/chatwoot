#!/usr/bin/env bash
# =============================================================================
# dev.sh - Script para gerenciar o ambiente de desenvolvimento do Chatwit v4.10
# =============================================================================
#
# Tudo roda em Docker. Basta executar:
#   ./dev.sh           → Sobe tudo
#   ./dev.sh -n        → Sobe tudo + ngrok (túnel público)
#
# E abrir: http://localhost:3000
#
# =============================================================================

set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Configurações
# ─────────────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.dev.yaml"
ENV_FILE="$SCRIPT_DIR/.env"
ENV_EXAMPLE="$SCRIPT_DIR/.env.example"
NGROK_MODE=false

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ─────────────────────────────────────────────────────────────────────────────
# Funções auxiliares
# ─────────────────────────────────────────────────────────────────────────────
log_info()    { echo -e "${BLUE}ℹ${NC}  $1"; }
log_success() { echo -e "${GREEN}✔${NC}  $1"; }
log_warn()    { echo -e "${YELLOW}⚠${NC}  $1"; }
log_error()   { echo -e "${RED}✖${NC}  $1"; }
log_header()  { echo -e "\n${BOLD}${CYAN}═══ $1 ═══${NC}\n"; }

# Verifica se .env existe, caso contrário cria a partir do .env.example
ensure_env_file() {
  if [ ! -f "$ENV_FILE" ]; then
    if [ -f "$ENV_EXAMPLE" ]; then
      log_warn "Arquivo .env não encontrado. Criando a partir de .env.example..."
      cp "$ENV_EXAMPLE" "$ENV_FILE"

      # Ajusta valores para funcionar dentro do Docker
      sed -i 's|^POSTGRES_HOST=.*|POSTGRES_HOST=postgres|' "$ENV_FILE"
      sed -i 's|^REDIS_URL=.*|REDIS_URL=redis://redis:6379|' "$ENV_FILE"
      sed -i 's|^SMTP_ADDRESS=.*|SMTP_ADDRESS=mailhog|' "$ENV_FILE"
      sed -i 's|^RAILS_ENV=.*|RAILS_ENV=development|' "$ENV_FILE"
      sed -i 's|^FRONTEND_URL=.*|FRONTEND_URL=http://localhost:3000|' "$ENV_FILE"

      log_success ".env criado com valores padrão para Docker!"
    else
      log_error "Nem .env nem .env.example encontrados!"
      exit 1
    fi
  fi
}

# Verifica dependências necessárias
check_dependencies() {
  local missing=()

  if ! command -v docker &> /dev/null; then
    missing+=("docker")
  fi

  if ! docker compose version &> /dev/null 2>&1; then
    if ! command -v docker-compose &> /dev/null; then
      missing+=("docker-compose")
    fi
  fi

  if [ ${#missing[@]} -gt 0 ]; then
    log_error "Dependências faltando: ${missing[*]}"
    log_info "Instale as dependências e tente novamente."
    exit 1
  fi
}

# Comando Docker Compose (suporta v1 e v2, com profile ngrok opcional)
dc() {
  local profile_args=()
  if [ "$NGROK_MODE" = true ]; then
    profile_args=("--profile" "ngrok")
  fi

  if docker compose version &> /dev/null 2>&1; then
    docker compose -f "$COMPOSE_FILE" "${profile_args[@]}" "$@"
  else
    docker-compose -f "$COMPOSE_FILE" "${profile_args[@]}" "$@"
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Comandos
# ─────────────────────────────────────────────────────────────────────────────

cmd_up() {
  log_header "Subindo ambiente de desenvolvimento completo"

  ensure_env_file

  # Sobe tudo (inicia em background e segue logs)
  dc up -d
  log_info "Exibindo logs (pressione Ctrl+C para sair sem parar os containers)..."
  dc logs -f --tail=100

  echo ""
  log_success "Ambiente de desenvolvimento pronto!"
  echo ""
  echo -e "  ${BOLD}${GREEN}URLs:${NC}"
  echo -e "  ${CYAN}🌐 Aplicação${NC}  → ${BOLD}http://localhost:3000${NC}"
  echo -e "  ${CYAN}⚡ Vite HMR${NC}   → http://localhost:3036"
  echo -e "  ${CYAN}📧 MailHog${NC}    → http://localhost:8025"
  if [ "$NGROK_MODE" = true ]; then
    echo -e "  ${CYAN}🔗 Ngrok${NC}      → ${BOLD}https://${NGROK_DOMAIN:-beagle-great-awfully.ngrok-free.app}${NC}"
    echo -e "  ${CYAN}🔗 Ngrok UI${NC}   → http://localhost:4040"
  fi
  echo ""
  echo -e "  ${BOLD}Infraestrutura:${NC}"
  echo -e "  ${CYAN}🐘 PostgreSQL${NC} → localhost:5433"
  echo -e "  ${CYAN}🔴 Redis${NC}      → localhost:6380"
  echo ""
  echo -e "  ${BOLD}Comandos úteis:${NC}"
  echo -e "    ./dev.sh logs          Ver logs de todos os serviços"
  echo -e "    ./dev.sh logs rails    Ver logs apenas do Rails"
  echo -e "    ./dev.sh shell         Abrir shell no container Rails"
  echo -e "    ./dev.sh console       Abrir Rails console"
  echo ""
}

cmd_build() {
  log_header "Rebuild das imagens"
  ensure_env_file
  dc build --no-cache
  log_success "Imagens reconstruídas!"
}

cmd_down() {
  log_header "Parando ambiente"
  dc down
  log_success "Ambiente parado."
}

cmd_restart() {
  log_header "Reiniciando ambiente"
  dc restart
  log_success "Ambiente reiniciado."
}

cmd_logs() {
  dc logs -f "$@"
}

cmd_status() {
  log_header "Status dos containers"
  dc ps -a
}

cmd_shell() {
  log_info "Abrindo shell no container Rails..."
  dc exec rails sh
}

cmd_console() {
  log_info "Abrindo Rails console..."
  dc exec rails bundle exec rails console
}

cmd_db_setup() {
  log_header "Configurando banco de dados"
  log_info "Criando banco e rodando migrations..."
  dc exec rails bundle exec rails db:prepare
  log_success "Banco de dados configurado!"
}

cmd_db_reset() {
  log_header "Resetando banco de dados"
  log_warn "Isso vai APAGAR todos os dados do banco!"
  read -p "Tem certeza? (y/N): " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    dc exec rails bundle exec rails db:reset
    log_success "Banco de dados resetado!"
  else
    log_info "Operação cancelada."
  fi
}

cmd_db_migrate() {
  log_header "Rodando migrations"
  dc exec rails bundle exec rails db:migrate
  log_success "Migrations aplicadas!"
}

cmd_clean() {
  log_header "Limpeza completa"
  log_warn "Isso vai PARAR os containers e REMOVER os volumes (dados do Postgres, Redis, gems, node_modules)!"
  read -p "Tem certeza? (y/N): " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    dc down -v --remove-orphans
    log_success "Containers parados e volumes removidos."
  else
    log_info "Operação cancelada."
  fi
}

cmd_help() {
  echo -e "${BOLD}${CYAN}"
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║          🚀  Chatwit v4.10 - Dev Environment               ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo -e "${NC}"
  echo -e "  ${BOLD}Uso:${NC} ./dev.sh [comando]"
  echo ""
  echo -e "  ${BOLD}Comandos principais:${NC}"
  echo -e "    ${GREEN}(sem argumento)${NC}   Sobe e segue logs (attach)"
  echo -e "    ${GREEN}-n${NC}                Sobe e segue logs + ngrok"
  echo -e "    ${GREEN}up${NC}                Sobe e segue logs (attach)"
  echo -e "    ${GREEN}build${NC}             Rebuild completo das imagens"
  echo -e "    ${GREEN}down${NC}              Para todos os containers"
  echo -e "    ${GREEN}restart${NC}           Reinicia todos os containers"
  echo ""
  echo -e "  ${BOLD}Monitoramento:${NC}"
  echo -e "    ${GREEN}logs [serviço]${NC}    Mostra logs (ex: logs rails)"
  echo -e "    ${GREEN}status${NC}            Mostra status dos containers"
  echo ""
  echo -e "  ${BOLD}Acesso:${NC}"
  echo -e "    ${GREEN}shell${NC}             Abre shell no container Rails"
  echo -e "    ${GREEN}console${NC}           Abre o Rails console"
  echo ""
  echo -e "  ${BOLD}Banco de dados:${NC}"
  echo -e "    ${GREEN}db:setup${NC}          Cria e migra o banco"
  echo -e "    ${GREEN}db:reset${NC}          Reseta o banco (APAGA DADOS!)"
  echo -e "    ${GREEN}db:migrate${NC}        Roda migrations pendentes"
  echo ""
  echo -e "  ${BOLD}Limpeza:${NC}"
  echo -e "    ${GREEN}clean${NC}             Remove containers + volumes"
  echo ""
  echo -e "  ${BOLD}URLs:${NC}"
  echo -e "    🌐 Aplicação   → ${BOLD}http://localhost:3000${NC}"
  echo -e "    ⚡ Vite HMR    → http://localhost:3036"
  echo -e "    📧 MailHog     → http://localhost:8025"
  echo -e "    🐘 PostgreSQL  → localhost:5433"
  echo -e "    🔴 Redis       → localhost:6380"
  echo -e "    🔗 Ngrok       → ./dev.sh -n (túnel público)"
  echo -e "    🔗 Ngrok UI    → http://localhost:4040"
  echo ""
}

# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────

check_dependencies

# Parse do flag -n (ngrok)
if [ "${1:-}" = "-n" ]; then
  NGROK_MODE=true
  shift
fi

case "${1:-}" in
  up)          cmd_up ;;
  build)       cmd_build ;;
  down)        cmd_down ;;
  restart)     cmd_restart ;;
  logs)        shift; cmd_logs "$@" ;;
  status)      cmd_status ;;
  shell)       cmd_shell ;;
  console)     cmd_console ;;
  db:setup)    cmd_db_setup ;;
  db:reset)    cmd_db_reset ;;
  db:migrate)  cmd_db_migrate ;;
  clean)       cmd_clean ;;
  help|-h|--help) cmd_help ;;
  "")          cmd_up ;;
  *)
    log_error "Comando desconhecido: $1"
    cmd_help
    exit 1
    ;;
esac
