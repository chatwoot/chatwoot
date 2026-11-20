# Delta local

Arquivos aditivos. Nenhum arquivo do upstream é modificado.

- config/initializers/zzz_premium_unlock.rb
- Dockerfile.premium
- docker-compose.premium.yml
- scripts/apply-premium.sh

Build: ./scripts/apply-premium.sh <tag>
Upgrade seguro: ./scripts/upgrade-premium.sh [tag]
Sync develop/main (sem tocar premium): ./scripts/sync-develop.sh
Rollback: trocar a imagem para chatwoot/chatwoot:<tag> e recriar
Desligar sem remover: PREMIUM_UNLOCK_DISABLE=1