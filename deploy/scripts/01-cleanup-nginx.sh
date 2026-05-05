#!/bin/bash
# Remove o Nginx residual da VPS.
# O Traefik faz o ingress; Nginx está com config quebrada e ocupando memória.
#
# Uso (na VPS):
#   bash 01-cleanup-nginx.sh

set -euo pipefail

echo "==> Estado atual do Nginx:"
sudo systemctl status nginx --no-pager | head -10 || true

echo ""
echo "==> Parando e desabilitando"
sudo systemctl disable --now nginx || true

echo ""
echo "==> Removendo pacotes"
sudo apt purge -y nginx nginx-common nginx-core || true
sudo apt autoremove -y

echo ""
echo "==> Confirmando que portas 80/443 continuam com Traefik:"
sudo ss -tlnp | grep -E ':80 |:443 ' || echo "    (Traefik usa hostmode no Swarm — pode não aparecer aqui)"

echo ""
echo "OK. Nginx removido."
