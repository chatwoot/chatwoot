#!/bin/bash
# Sobe o registry self-hosted na VPS.
# Pré-requisitos: DNS, network do Traefik, htpasswd já criado.
#
# Antes de rodar:
#   1. Confirmar que o DNS A `registry.dexidigital.com.br` aponta para 158.69.63.140
#   2. Conferir o nome real da network do Traefik:
#         sudo docker network ls | grep -i traefik
#      Se não for "traefik", ajustar deploy/registry/docker-stack.yml
#   3. Conferir o nome do certresolver:
#         sudo docker service inspect traefik_traefik --format '{{json .Spec.TaskTemplate.ContainerSpec.Args}}' | tr ',' '\n' | grep -i certresolver
#      Se não for "letsencrypt", ajustar o YAML
#   4. Gerar htpasswd e copiar para /opt/registry/htpasswd:
#         sudo mkdir -p /opt/registry
#         sudo docker run --rm --entrypoint htpasswd httpd:2 -Bbn synapseos '<SENHA>' \
#           | sudo tee /opt/registry/htpasswd
#         sudo chmod 644 /opt/registry/htpasswd
#
# Uso (na VPS, dentro de ~/deploy/registry):
#   bash ../scripts/02-deploy-registry.sh

set -euo pipefail

cd "$(dirname "$0")/../registry"

echo "==> Conferindo pré-requisitos"
[ -f /opt/registry/htpasswd ] || { echo "ERRO: /opt/registry/htpasswd não existe"; exit 1; }
sudo docker network ls --format '{{.Name}}' | grep -q '^traefik$' \
  || { echo "ERRO: network 'traefik' não existe — ajustar YAML"; exit 1; }

echo "==> Deploy"
sudo docker stack deploy -c docker-stack.yml registry

echo "==> Aguardando service ficar pronto (até 60s)"
for i in {1..30}; do
  sleep 2
  REPLICAS=$(sudo docker service ls --filter name=registry_registry --format '{{.Replicas}}')
  echo "    $REPLICAS"
  if [[ "$REPLICAS" == "1/1" ]]; then break; fi
done

echo ""
echo "==> Logs (10 últimas linhas)"
sudo docker service logs --tail 10 registry_registry

echo ""
echo "==> Esperando Let's Encrypt emitir cert (até 90s)"
for i in {1..15}; do
  sleep 6
  if curl -sS -o /dev/null -w "" https://registry.dexidigital.com.br/v2/ 2>/dev/null; then
    echo "    cert ativo"
    break
  fi
  echo "    ainda não..."
done

echo ""
echo "==> Teste de auth"
curl -sS -u synapseos:'<SENHA>' https://registry.dexidigital.com.br/v2/_catalog
echo ""
echo "OK. Registry no ar."
