#!/bin/bash
# Rolling update do Chatwoot Synapseos em produção (Docker Swarm).
# Roda na VPS.
#
# Substitui a imagem dos services chatwoot_app e chatwoot_sidekiq
# SEM derrubar volumes nem reiniciar redis. Mantém banco e dados intactos.
#
# Uso:
#   bash 05-rolling-update.sh v0.1.3-synapseos

set -euo pipefail

TAG="${1:?uso: $0 <tag>  (ex: v0.1.3-synapseos)}"
REGISTRY="ghcr.io"
IMAGE_OWNER="paraisolorrayne"
IMAGE="$REGISTRY/$IMAGE_OWNER/synapseos-chatwoot:$TAG"

echo "==> Imagem alvo: $IMAGE"
echo "==> Confirmando que existe no registry"
sudo docker pull "$IMAGE"

echo ""
echo "==> Estado atual"
sudo docker service ls --filter name=chatwoot_

echo ""
echo "==> Imagem atual em produção:"
sudo docker service inspect chatwoot_app --format '    chatwoot_app: {{.Spec.TaskTemplate.ContainerSpec.Image}}'
sudo docker service inspect chatwoot_sidekiq --format '    chatwoot_sidekiq: {{.Spec.TaskTemplate.ContainerSpec.Image}}'

echo ""
read -p "Aplicar rolling update para $TAG? [y/N] " ok
[[ "$ok" == "y" || "$ok" == "Y" ]] || exit 1

echo ""
echo "==> Atualizando chatwoot_app (Swarm vai criar novo task e drenar o antigo)"
sudo docker service update \
  --image "$IMAGE" \
  --update-parallelism 1 \
  --update-failure-action rollback \
  chatwoot_app

echo ""
echo "==> Atualizando chatwoot_sidekiq"
sudo docker service update \
  --image "$IMAGE" \
  --update-parallelism 1 \
  --update-failure-action rollback \
  chatwoot_sidekiq

echo ""
echo "==> Aguardando rollout (até 3min)"
for i in {1..90}; do
  sleep 2
  APP_STATE=$(sudo docker service ls --filter name=chatwoot_app --format '{{.Replicas}}')
  SK_STATE=$(sudo docker service ls --filter name=chatwoot_sidekiq --format '{{.Replicas}}')
  echo "    chatwoot_app: $APP_STATE | chatwoot_sidekiq: $SK_STATE"
  if [[ "$APP_STATE" == "1/1" && "$SK_STATE" == "1/1" ]]; then break; fi
done

echo ""
echo "==> Migrations (rodar manualmente se a release contiver alguma)"
echo "    APP_CID=\$(sudo docker ps -q -f name=chatwoot_app | head -1)"
echo "    sudo docker exec \$APP_CID bundle exec rails db:migrate"

echo ""
echo "==> Validações sugeridas"
echo "    curl -I https://chat.dexidigital.com.br/                       # 200"
echo "    curl -I https://chat.dexidigital.com.br/super_admin/sign_in    # 200"

echo ""
echo "==> Rollback se algo der errado:"
echo "    sudo docker service rollback chatwoot_app"
echo "    sudo docker service rollback chatwoot_sidekiq"

echo ""
echo "OK. Rolling update concluído (validar em https://chat.dexidigital.com.br)"
