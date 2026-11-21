#!/usr/bin/env bash
# Atualização segura da branch premium para uma nova tag do upstream.
# Uso: scripts/upgrade-premium.sh [v4.20.0]   (se omitir, usa a tag mais recente do upstream)
set -euo pipefail
cd "$(dirname "$0")/.."

BASE="docker-compose.production.yaml"
[ -f "$BASE" ] || BASE="docker-compose.yaml"

TARGET_TAG="${1:-}"

# 1) Descobrir a tag alvo
git fetch upstream --tags >/dev/null
if [[ -z "$TARGET_TAG" ]]; then
  TARGET_TAG=$(git tag -l 'v*' --sort=-v:refname | head -n1)
  echo "Tag alvo detectada automaticamente: $TARGET_TAG"
fi

# 2) Validações de segurança
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT_BRANCH" != "premium" ]]; then
  echo "ERRO: você não está na branch premium (atual: $CURRENT_BRANCH)."
  echo "      Rode: git checkout premium"
  exit 1
fi
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "ERRO: working tree sujo. Commit ou stash antes de atualizar."
  exit 1
fi
if ! git rev-parse "$TARGET_TAG" >/dev/null 2>&1; then
  echo "ERRO: tag '$TARGET_TAG' não existe no upstream."
  exit 1
fi

echo "=============================================="
echo "  Upgrade premium -> $TARGET_TAG"
echo "=============================================="
read -r -p "Confirma a atualização? (s/N) " ans
[[ "$ans" =~ ^[sS]$ ]] || { echo "Cancelado pelo usuário."; exit 0; }

# Ajustes específicos do servidor no compose de produção (não commitados)
sed -i 's|      - POSTGRES_PASSWORD=.*|      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}|' "$BASE"
sed -i "s|      - '127.0.0.1:3000:3000'|      - '3000:3000'|" "$BASE"

# 3) Backup do Postgres (se estiver rodando)
BACKUP_FILE="/backup/chatwoot-pre-${TARGET_TAG}-$(date +%F-%H%M).sql.gz"
COMPOSE="docker compose -f $BASE -f docker-compose.premium.yml"
if [[ -n "$($COMPOSE ps -q postgres 2>/dev/null)" ]]; then
  echo "Gerando backup em $BACKUP_FILE ..."
  mkdir -p /backup
  $COMPOSE exec -T postgres pg_dump -U postgres chatwoot | gzip > "$BACKUP_FILE"
  echo "Backup OK: $BACKUP_FILE"
else
  echo "AVISO: postgres não está rodando; backup pulado. Continue por sua conta e risco."
fi

# 4) Merge (nunca rebase) do upstream na premium
echo "Fazendo merge de $TARGET_TAG na premium ..."
git merge --no-ff "$TARGET_TAG" -m "[premium] merge $TARGET_TAG"

# 5) Tag e push
git tag "premium-${TARGET_TAG}" 2>/dev/null || echo "Tag premium-${TARGET_TAG} já existia; pulando criação."
git push origin premium --tags || echo "AVISO: push falhou (sem credenciais no servidor). Publique manualmente: git push origin premium --tags"

# 6) Build + subida + canário (reaproveita apply-premium.sh)
./scripts/apply-premium.sh "$TARGET_TAG"

# 6.1) Migrar banco (caso a nova versão traga migrations)
docker compose -f "$BASE" -f docker-compose.premium.yml exec -T rails bundle exec rails db:chatwoot_prepare 2>&1 | tail -5

# 7) Verificação do unlock
echo "Verificando unlock ..."
PLAN=$($COMPOSE exec -T rails bundle exec rails runner 'puts "PREMIUM_CANARY_PLAN=#{ChatwootHub.pricing_plan}"' 2>/dev/null | grep -o 'PREMIUM_CANARY_PLAN=[^[:space:]]*' | head -n1 | cut -d= -f2)
PAID=$($COMPOSE exec -T rails bundle exec rails runner 'puts "PREMIUM_CANARY_PAID=#{ChatwootApp.self_hosted_paid?}"' 2>/dev/null | grep -o 'PREMIUM_CANARY_PAID=[^[:space:]]*' | head -n1 | cut -d= -f2)
SLA=$($COMPOSE exec -T rails bundle exec rails runner 'puts "PREMIUM_CANARY_SLA=#{Account.first&.feature_enabled?(:sla)}"' 2>/dev/null | grep -o 'PREMIUM_CANARY_SLA=[^[:space:]]*' | head -n1 | cut -d= -f2)
echo "canário: plano=$PLAN self_hosted_paid=$PAID sla=$SLA"

if [[ "$PLAN" != "enterprise" || "$PAID" != "true" || "$SLA" != "true" ]]; then
  echo "FALHOU na verificação do unlock."
  echo "  - Consulte: docker compose logs rails --tail 100"
  echo "  - Rollback rápido: git checkout premium && git reset --hard premium-${TARGET_TAG}^"
  echo "  - Restaure o backup: $BACKUP_FILE"
  exit 1
fi

echo "=============================================="
echo "  OK — premium atualizada para $TARGET_TAG"
echo "=============================================="
echo "Rollback (se necessário):"
echo "  git checkout premium && git reset --hard premium-${TARGET_TAG}^"
echo "  # e restaure o backup: $BACKUP_FILE"