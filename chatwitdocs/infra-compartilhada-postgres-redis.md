# Infra Compartilhada de Desenvolvimento

## Objetivo

Reduzir consumo de memória local usando um único PostgreSQL `pgvector/pgvector:pg17` e um único Redis `8.6.1` compartilhados entre:

- Chatwit
- Socialwise
- JusMonitorIA

## Infra compartilhada

- Compose isolado: `/home/wital/shared-infra/docker-compose.yml`
- Rede Docker externa: `minha_rede`
- Containers fixos:
  - `postgres`
  - `redis`
- Portas expostas:
  - PostgreSQL: `5432`
  - Redis: `6379`

## Bancos provisionados no startup do Postgres

- `chatwoot`
- `socialwise`
- `jusmonitoria`

Também é criado o usuário `jusmonitoria` com a senha usada no ambiente local atual, e a extensão `vector` é habilitada nos três bancos.

## Ajustes realizados

- Removidos `postgres` e `redis` dos compose locais:
  - `docker-compose.dev.yaml` do Chatwit
  - `docker-compose-dev.yml` do Socialwise
  - `docker-compose-dev-ngrok.yml` do Socialwise
  - `docker-compose.yml` do JusMonitorIA
- Todos os serviços agora entram na rede `minha_rede` e resolvem dependências pelos hosts `postgres` e `redis`.
- Os `dev.sh` dos três projetos agora:
  - criam a rede `minha_rede` se necessário
  - sobem a infra compartilhada se `postgres` ou `redis` não estiverem ativos
  - aguardam readiness antes de subir a stack da aplicação

## Observação operacional

Os comandos `clean` e `build hard` dos projetos foram ajustados para não apagar a infra compartilhada, evitando impacto cruzado entre os três ambientes.