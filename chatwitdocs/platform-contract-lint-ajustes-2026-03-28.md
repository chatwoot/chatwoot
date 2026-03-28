# Ajustes de lint para contrato unificado da plataforma

**Data:** 2026-03-28

## Contexto

Com a consolidacao do contrato na Witdev Platform Core, os inicializadores de bot e o forwarder do JusMonitorIA precisaram permanecer alinhados ao backend unico `https://api.witdev.com.br`, com os paths por dominio:

- Socialwise: `/api/integrations/webhooks/socialwiseflow/init`
- JusMonitorIA init: `/api/v1/jusmonitoria/integrations/chatwit/init`
- JusMonitorIA webhook: `/webhooks/chatwit`

## Ajustes aplicados

- Refactor de `config/initializers/socialwise_bot.rb` para extrair `provision!`, criacao do bot e registro do token no endpoint `/init`.
- Refactor de `config/initializers/jusmonitoria_bot.rb` para extrair `provision!`, auto-provisionamento das labels e registro do token no endpoint `/init`.
- Refactor de `lib/integrations/jusmonitoria/webhook_forwarder_service.rb` para separar montagem de payload e POST HTTP.
- Supressoes locais de RuboCop em `lib/integrations/socialwise_flow/processor_service.rb` para o arquivo legado da migracao, evitando bloquear commits enquanto a decomposicao da classe nao e feita.

## Observacao

Os endpoints usados nesses arquivos ja estao de acordo com a fonte de verdade em `/home/wital/witdev-platform-core/docs/contrato-plataforma-unificada.md`.
