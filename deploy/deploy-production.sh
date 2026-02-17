#!/bin/bash
set -euo pipefail

# =============================================================================
# convertoChat - Script de Deploy para Produção
# =============================================================================
# Uso: ./deploy-production.sh [build|deploy|backup|rollback|branding|status]
#
# Pré-requisitos:
#   - Docker e Docker Compose instalados no servidor
#   - Git instalado no servidor
#   - Acesso ao repositório: https://github.com/valter-tonon/chatwoot.git
# =============================================================================

REPO_URL="https://github.com/valter-tonon/chatwoot.git"
BRANCH="upgrade/v4.10.1"
IMAGE_NAME="convertochat"
IMAGE_TAG="v4.10.1"
COMPOSE_FILE="docker-compose.production.yaml"
BACKUP_DIR="./backups"
APP_DIR="$(pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ---- BACKUP ----
do_backup() {
    log_info "Iniciando backup..."
    mkdir -p "$BACKUP_DIR"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)

    log_info "Backup do PostgreSQL..."
    docker compose -f "$COMPOSE_FILE" exec -T postgres \
        pg_dump -U postgres chatwoot_production \
        > "${BACKUP_DIR}/db_backup_${TIMESTAMP}.sql"

    if [ $? -eq 0 ]; then
        log_info "Backup do banco salvo em: ${BACKUP_DIR}/db_backup_${TIMESTAMP}.sql"
    else
        log_error "Falha no backup do banco!"
        exit 1
    fi

    log_info "Backup dos volumes de storage..."
    docker run --rm \
        -v "$(docker volume ls -q | grep storage_data | head -1)":/data \
        -v "$(pwd)/${BACKUP_DIR}":/backup \
        alpine tar czf "/backup/storage_backup_${TIMESTAMP}.tar.gz" -C /data . 2>/dev/null || \
        log_warn "Nenhum volume de storage encontrado (pode ser normal em instalações novas)"

    log_info "Salvando docker-compose atual como backup..."
    cp "$COMPOSE_FILE" "${BACKUP_DIR}/${COMPOSE_FILE}.backup_${TIMESTAMP}"

    log_info "Backup completo!"
    ls -lh "${BACKUP_DIR}/"*"${TIMESTAMP}"* 2>/dev/null
}

# ---- BUILD ----
do_build() {
    log_info "Iniciando build da imagem ${IMAGE_NAME}:${IMAGE_TAG}..."

    if [ ! -d ".git" ]; then
        log_info "Clonando repositório..."
        cd /tmp
        rm -rf convertochat-build
        git clone --branch "$BRANCH" --single-branch "$REPO_URL" convertochat-build
        cd convertochat-build
    else
        log_info "Usando repositório local..."
        git fetch origin
        git checkout "$BRANCH"
        git pull origin "$BRANCH"
    fi

    log_info "Buildando imagem Docker (pode levar 10-15 minutos)..."
    docker build \
        -f docker/Dockerfile \
        -t "${IMAGE_NAME}:${IMAGE_TAG}" \
        -t "${IMAGE_NAME}:latest" \
        .

    if [ $? -eq 0 ]; then
        log_info "Imagem buildada com sucesso!"
        docker images "${IMAGE_NAME}" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
    else
        log_error "Falha no build!"
        exit 1
    fi
}

# ---- DEPLOY ----
do_deploy() {
    log_info "Iniciando deploy..."

    if ! docker images "${IMAGE_NAME}:${IMAGE_TAG}" --format "{{.ID}}" | grep -q .; then
        log_error "Imagem ${IMAGE_NAME}:${IMAGE_TAG} não encontrada. Execute './deploy-production.sh build' primeiro."
        exit 1
    fi

    if ! [ -f "$COMPOSE_FILE" ]; then
        log_error "Arquivo ${COMPOSE_FILE} não encontrado!"
        exit 1
    fi

    log_warn "Isso vai parar a aplicação por alguns minutos."
    read -p "Continuar? (s/N): " confirm
    if [[ "$confirm" != "s" && "$confirm" != "S" ]]; then
        log_info "Deploy cancelado."
        exit 0
    fi

    log_info "Parando containers atuais..."
    docker compose -f "$COMPOSE_FILE" down

    log_info "Subindo com a nova imagem..."
    docker compose -f "$COMPOSE_FILE" up -d

    log_info "Aguardando containers ficarem saudáveis (30s)..."
    sleep 30

    log_info "Rodando migrations..."
    docker compose -f "$COMPOSE_FILE" exec -T rails \
        bundle exec rails db:chatwoot_prepare || {
            log_warn "db:chatwoot_prepare falhou, tentando db:migrate..."
            docker compose -f "$COMPOSE_FILE" exec -T rails \
                bundle exec rails db:migrate
        }

    log_info "Deploy concluído!"
    do_status
}

# ---- BRANDING ----
do_branding() {
    log_info "Aplicando branding convertoChat..."

    docker compose -f "$COMPOSE_FILE" exec -T rails \
        bundle exec rails runner '
configs = {
  "INSTALLATION_NAME" => "convertoChat",
  "BRAND_NAME" => "convertoChat",
  "LOGO" => "/chat.png",
  "LOGO_DARK" => "/chat.png",
  "LOGO_THUMBNAIL" => "/chat.png",
  "BRAND_URL" => "https://www.convertochat.com",
  "WIDGET_BRAND_URL" => "https://www.convertochat.com",
  "INSTALLATION_PRICING_PLAN" => "enterprise"
}
configs.each do |name, value|
  c = InstallationConfig.find_or_initialize_by(name: name)
  c.update!(value: value)
  puts "  #{name} = #{value}"
end

ai_configs = [
  ["CAPTAIN_AI_PROVIDER", "openai"],
  ["CAPTAIN_GEMINI_API_KEY", ""],
  ["CAPTAIN_GEMINI_MODEL", "gemini-2.0-flash"],
  ["CAPTAIN_DEEPSEEK_API_KEY", ""],
  ["CAPTAIN_DEEPSEEK_MODEL", "deepseek-chat"]
]
ai_configs.each do |name, value|
  unless InstallationConfig.exists?(name: name)
    InstallationConfig.create!(name: name, value: value, locked: false)
    puts "  Created #{name} = #{value}"
  else
    puts "  Already exists: #{name}"
  end
end
puts "\nBranding aplicado com sucesso!"
'

    log_info "Branding aplicado!"
}

# ---- ROLLBACK ----
do_rollback() {
    log_info "Iniciando rollback..."

    LATEST_BACKUP=$(ls -t "${BACKUP_DIR}"/db_backup_*.sql 2>/dev/null | head -1)
    LATEST_COMPOSE=$(ls -t "${BACKUP_DIR}"/${COMPOSE_FILE}.backup_* 2>/dev/null | head -1)

    if [ -z "$LATEST_BACKUP" ]; then
        log_error "Nenhum backup encontrado em ${BACKUP_DIR}/"
        exit 1
    fi

    log_warn "Último backup encontrado: $LATEST_BACKUP"
    log_warn "ATENÇÃO: Isso vai restaurar o banco ao estado do backup. Dados criados após o backup serão PERDIDOS."
    read -p "Continuar com rollback? (s/N): " confirm
    if [[ "$confirm" != "s" && "$confirm" != "S" ]]; then
        log_info "Rollback cancelado."
        exit 0
    fi

    log_info "Parando containers..."
    docker compose -f "$COMPOSE_FILE" down

    if [ -n "$LATEST_COMPOSE" ]; then
        log_info "Restaurando docker-compose original..."
        cp "$LATEST_COMPOSE" "$COMPOSE_FILE"
    fi

    log_info "Subindo containers..."
    docker compose -f "$COMPOSE_FILE" up -d

    sleep 15

    log_info "Restaurando banco de dados..."
    docker compose -f "$COMPOSE_FILE" exec -T postgres \
        psql -U postgres chatwoot_production < "$LATEST_BACKUP"

    log_info "Reiniciando aplicação..."
    docker compose -f "$COMPOSE_FILE" restart rails sidekiq

    log_info "Rollback concluído!"
    do_status
}

# ---- STATUS ----
do_status() {
    log_info "Status dos containers:"
    docker compose -f "$COMPOSE_FILE" ps

    echo ""
    log_info "Verificando aplicação..."
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 http://localhost:3000 2>/dev/null || echo "000")

    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
        log_info "Aplicação respondendo (HTTP ${HTTP_CODE})"

        BRAND=$(curl -s --max-time 10 http://localhost:3000 2>/dev/null | grep -o 'INSTALLATION_NAME":"[^"]*"' | head -1 || echo "")
        if echo "$BRAND" | grep -q "convertoChat"; then
            log_info "Branding: convertoChat ✓"
        else
            log_warn "Branding: Chatwoot padrão (execute './deploy-production.sh branding' para aplicar)"
        fi

        VERSION=$(curl -s --max-time 10 http://localhost:3000 2>/dev/null | grep -o 'APP_VERSION":"[^"]*"' | head -1 || echo "")
        log_info "Versão: $VERSION"
    else
        log_error "Aplicação não respondendo (HTTP ${HTTP_CODE})"
        log_warn "Verifique os logs: docker compose -f ${COMPOSE_FILE} logs rails --tail 50"
    fi
}

# ---- HELP ----
show_help() {
    echo "convertoChat - Script de Deploy para Produção"
    echo ""
    echo "Uso: $0 <comando>"
    echo ""
    echo "Comandos:"
    echo "  backup    - Backup do banco e volumes (SEMPRE execute antes do deploy)"
    echo "  build     - Build da imagem Docker a partir do repositório"
    echo "  deploy    - Para containers, sobe nova versão, roda migrations"
    echo "  branding  - Aplica branding convertoChat no banco de dados"
    echo "  rollback  - Restaura último backup (banco + docker-compose)"
    echo "  status    - Verifica status da aplicação"
    echo ""
    echo "Fluxo completo:"
    echo "  1. $0 backup"
    echo "  2. $0 build"
    echo "  3. $0 deploy"
    echo "  4. $0 branding"
    echo "  5. $0 status"
}

# ---- MAIN ----
case "${1:-help}" in
    backup)   do_backup ;;
    build)    do_build ;;
    deploy)   do_deploy ;;
    branding) do_branding ;;
    rollback) do_rollback ;;
    status)   do_status ;;
    *)        show_help ;;
esac
