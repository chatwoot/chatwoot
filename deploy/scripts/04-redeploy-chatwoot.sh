#!/bin/bash
# Substitui a imagem do Chatwoot oficial pelo fork Synapseos.
# Roda na VPS.
#
# IMPORTANTE: Esse script DESCARTA os dados atuais do Chatwoot (autorizado).
# Se mudar de ideia, faça backup com 00-backup-postgres.sh ANTES.
#
# Uso:
#   bash 04-redeploy-chatwoot.sh v0.1.0-synapseos

set -euo pipefail

TAG="${1:?uso: $0 <tag>}"
REGISTRY="registry.dexidigital.com.br"
IMAGE="$REGISTRY/synapseos-chatwoot:$TAG"

echo "==> Imagem alvo: $IMAGE"
echo "==> Confirmando que existe no registry"
sudo docker pull "$IMAGE"

echo ""
echo "==> Estado atual"
sudo docker service ls --filter name=chatwoot_

echo ""
read -p "ATENÇÃO: isso vai descartar dados do Chatwoot atual. Continuar? [y/N] " ok
[[ "$ok" == "y" || "$ok" == "Y" ]] || exit 1

echo ""
echo "==> Removendo stack atual (preserva volumes)"
sudo docker stack rm chatwoot
echo "    aguardando services serem removidos"
sleep 15

echo ""
echo "==> Limpando volumes do Chatwoot (DESCARTE explícito)"
sudo docker volume ls --format '{{.Name}}' | grep -E '^chatwoot_' | while read v; do
  echo "    rm volume: $v"
  sudo docker volume rm "$v" || true
done

echo ""
echo "==> Subindo stack do fork"
echo "    (usar manifesto em ~/deploy/chatwoot/docker-stack.yml)"
cd "$(dirname "$0")/../chatwoot"
TAG="$TAG" sudo -E docker stack deploy -c docker-stack.yml chatwoot

echo ""
echo "==> Aguardando rollout (até 3min)"
for i in {1..90}; do
  sleep 2
  STATE=$(sudo docker service ls --filter name=chatwoot_chatwoot_app --format '{{.Replicas}}')
  echo "    chatwoot_app: $STATE"
  if [[ "$STATE" == "1/1" ]]; then break; fi
done

echo ""
echo "==> Logs do app"
sudo docker service logs --tail 30 chatwoot_chatwoot_app

echo ""
echo "==> Migrations (rodar manualmente após app estar up)"
echo "    APP_CID=\$(sudo docker ps -q -f name=chatwoot_chatwoot_app | head -1)"
echo "    sudo docker exec \$APP_CID bundle exec rails db:chatwoot_prepare"

echo ""
echo "OK. Chatwoot do fork no ar (validar em https://chat.dexidigital.com.br)"
