#!/usr/bin/env bash
# CUSTOMIZAÇÃO_SYNAPSEOS — release one-command da stack na VPS de produção.
#
# Roda do SEU MAC. Faz o deploy remoto: reusa o ./deploy.sh que já existe na VPS
# (git pull do compose + docker compose pull da imagem nova do ghcr + up -d +
# prune) e depois verifica o log do Avisa. A stack do compose sobe AS DUAS
# imagens (Chatwoot fork `synapseos-core` + panel `synapseos-agentic`).
#
# Pré-requisitos:
#   1. PR mergeado na branch que dispara `publish_synapseos_docker.yml`
#      (main / custom/initial-cleanup) e o build ✅ no GitHub Actions (a imagem
#      `ghcr.io/.../synapseos-core:latest` precisa estar publicada ANTES).
#   2. Acesso SSH à VPS.
#
# Uso:
#   VPS_HOST=ubuntu@158.69.63.140 ./deploy/release.sh
#   VPS_HOST=ubuntu@1.2.3.4 VPS_PATH=/opt/synapseos-core DEPLOY_BRANCH=main ./deploy/release.sh
set -euo pipefail

VPS_HOST="${VPS_HOST:?defina VPS_HOST=ubuntu@IP_DA_VPS}"
VPS_PATH="${VPS_PATH:-/opt/synapseos-core}"
DEPLOY_BRANCH="${DEPLOY_BRANCH:-main}"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.prod.yml}"

echo "==> Release Synapse OS"
echo "    host:   ${VPS_HOST}"
echo "    path:   ${VPS_PATH}"
echo "    branch: ${DEPLOY_BRANCH}"
echo ""

# 1. Deploy remoto (reusa o deploy.sh idempotente que já vive na VPS).
echo "==> Rodando deploy.sh na VPS (pull do compose + pull da imagem + up -d)..."
ssh "${VPS_HOST}" "set -e; cd '${VPS_PATH}'; DEPLOY_BRANCH='${DEPLOY_BRANCH}' COMPOSE_FILE='${COMPOSE_FILE}' ./deploy.sh"

# 2. Verificação: o serviço web deve estar up e o worker processando.
echo ""
echo "==> Status dos serviços:"
ssh "${VPS_HOST}" "cd '${VPS_PATH}'; docker compose -f '${COMPOSE_FILE}' ps web worker"

# 3. Sanity do fix de áudio: procura warnings do Avisa nos últimos logs.
echo ""
echo "==> Últimos logs do Avisa (download_audio etc.):"
ssh "${VPS_HOST}" "cd '${VPS_PATH}'; docker compose -f '${COMPOSE_FILE}' logs --tail=80 web worker 2>/dev/null | grep -i avisa || echo '    (sem linhas [AVISA] recentes — normal se ninguém mandou áudio ainda)'"

echo ""
echo "==> Deploy concluído."
echo "    Teste real: mande um ÁUDIO como cliente numa conversa de disparo →"
echo "    deve aparecer como mensagem de ENTRADA com player no Chatwoot."
echo "    Logs ao vivo: ssh ${VPS_HOST} \"cd ${VPS_PATH} && docker compose -f ${COMPOSE_FILE} logs -f --tail=100 web worker\""
