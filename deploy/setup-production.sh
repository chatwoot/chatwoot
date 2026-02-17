#!/bin/bash
set -euo pipefail

# =============================================================================
# convertoChat - Setup Inicial do Servidor de Producao
# =============================================================================
# Execute APENAS UMA VEZ no servidor Contabo antes do primeiro deploy via pipeline.
#
# Uso:
#   curl -sSL https://raw.githubusercontent.com/valter-tonon/chatwoot/upgrade/v4.10.1/deploy/setup-production.sh | bash
#   OU
#   git clone --branch upgrade/v4.10.1 --depth 1 https://github.com/valter-tonon/chatwoot.git /tmp/convertochat-setup
#   bash /tmp/convertochat-setup/deploy/setup-production.sh
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

WORK_DIR="/root"
COMPOSE_FILE="${WORK_DIR}/docker-compose.yaml"

log_info "=== Setup convertoChat - Producao ==="
echo ""

# --- Verificacoes ---
if [ ! -f "$COMPOSE_FILE" ]; then
    log_error "docker-compose.yaml nao encontrado em $WORK_DIR"
    exit 1
fi

if ! docker compose version > /dev/null 2>&1; then
    log_error "Docker Compose nao encontrado"
    exit 1
fi

# --- Backup ---
log_info "[1/5] Fazendo backup do estado atual..."

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
cp "$COMPOSE_FILE" "${COMPOSE_FILE}.backup_pre_convertochat_${TIMESTAMP}"
cp "${WORK_DIR}/.env" "${WORK_DIR}/.env.backup_pre_convertochat_${TIMESTAMP}" 2>/dev/null || true

docker compose -f "$COMPOSE_FILE" exec -T postgres \
    pg_dump -U postgres chatwoot_production \
    > "${WORK_DIR}/backup_pre_convertochat_${TIMESTAMP}.sql"

BACKUP_SIZE=$(wc -c < "${WORK_DIR}/backup_pre_convertochat_${TIMESTAMP}.sql")
if [ "$BACKUP_SIZE" -lt 1000 ]; then
    log_error "Backup parece vazio ou muito pequeno (${BACKUP_SIZE} bytes). Abortando."
    exit 1
fi
log_info "Backup do banco: ${WORK_DIR}/backup_pre_convertochat_${TIMESTAMP}.sql (${BACKUP_SIZE} bytes)"

# --- Atualizar docker-compose.yaml ---
log_info "[2/5] Atualizando docker-compose.yaml para usar imagem convertoChat..."

if grep -q "chatwoot/chatwoot" "$COMPOSE_FILE"; then
    sed -i 's|image: chatwoot/chatwoot:.*|image: ghcr.io/valter-tonon/chatwoot:latest|g' "$COMPOSE_FILE"
    log_info "Imagem atualizada para ghcr.io/valter-tonon/chatwoot:latest"
elif grep -q "ghcr.io/valter-tonon/chatwoot" "$COMPOSE_FILE"; then
    log_info "Imagem ja esta configurada para ghcr.io/valter-tonon/chatwoot"
else
    log_error "Nao foi possivel identificar a imagem no docker-compose.yaml"
    exit 1
fi

# --- Pull e restart ---
log_info "[3/5] Baixando imagem e reiniciando..."

docker pull ghcr.io/valter-tonon/chatwoot:latest

docker compose -f "$COMPOSE_FILE" down
docker compose -f "$COMPOSE_FILE" up -d

log_info "Aguardando Rails iniciar (60s)..."
sleep 60

# --- Migrations ---
log_info "[4/5] Rodando migrations..."

docker compose -f "$COMPOSE_FILE" exec -T rails \
    bundle exec rails db:chatwoot_prepare 2>&1 || {
        log_warn "db:chatwoot_prepare falhou, tentando db:migrate..."
        docker compose -f "$COMPOSE_FILE" exec -T rails \
            bundle exec rails db:migrate
    }

# --- Branding ---
log_info "[5/5] Aplicando branding convertoChat..."

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
    puts "  Created #{name}"
  else
    puts "  Already exists: #{name}"
  end
end
'

# --- Health check ---
echo ""
log_info "=== Verificacao final ==="

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 30 http://localhost:3000 2>/dev/null || echo "000")

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
    log_info "Aplicacao respondendo (HTTP ${HTTP_CODE})"

    BRAND=$(curl -s --max-time 10 http://localhost:3000 2>/dev/null | grep -o 'INSTALLATION_NAME":"[^"]*"' || echo "")
    if echo "$BRAND" | grep -q "convertoChat"; then
        log_info "Branding: convertoChat OK"
    else
        log_warn "Branding pode nao ter sido aplicado. Verifique manualmente."
    fi
else
    log_error "Aplicacao nao respondendo (HTTP ${HTTP_CODE})"
    log_warn "Verifique: docker compose logs rails --tail 50"
fi

echo ""
log_info "=== Setup concluido! ==="
echo ""
echo "Proximos passos:"
echo "  1. Configure os GitHub Secrets no repositorio:"
echo "     - SERVER_HOST: IP deste servidor"
echo "     - SERVER_USER: root"
echo "     - SERVER_PASSWORD: sua senha SSH"
echo "     - SERVER_PORT: 22"
echo ""
echo "  2. A partir de agora, todo push na branch fara deploy automatico."
echo ""
echo "  Rollback (se necessario):"
echo "     cp ${COMPOSE_FILE}.backup_pre_convertochat_${TIMESTAMP} ${COMPOSE_FILE}"
echo "     docker compose down && docker compose up -d"
echo "     docker compose exec -T postgres psql -U postgres chatwoot_production < backup_pre_convertochat_${TIMESTAMP}.sql"
