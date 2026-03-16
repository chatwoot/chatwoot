# Synapsea Analytics Service (Scaffold)

Backend Node.js scaffold para o módulo de relatórios estruturados + relatórios dinâmicos com IA do Synapsea Connect.

## Estrutura

- `src/modules/events`: ingestão de eventos operacionais (`event_store` pipeline)
- `src/modules/reports`: endpoints fixos de dashboards
- `src/modules/ai-reports`: camada "pergunte à IA" com guardrails
- `src/modules/routing`: motor operacional de filas, transferência e capacidade
- `src/modules/automations`: motor de regras (gatilho → condição → ação) com logs e cooldown
- `src/modules/supervisor`: torre de controle operacional em tempo real (overview, filas, capacidade, alertas)
- `src/modules/sdr`: SDR autônomo (importação de leads, prospecção, qualificação e métricas)
- `src/modules/platform`: blueprint técnico, camadas e catálogo de eventos canônicos
- `src/lib/metricsCatalog.ts`: catálogo oficial de métricas permitidas

## Endpoints iniciais

- `GET /health`
- `POST /api/events`
- `GET /api/reports/overview`
- `POST /api/reports/ask-ai`

## Endpoints de roteamento operacional (MVP)

- `POST /api/tickets`
- `POST /api/tickets/:id/transfer`
- `POST /api/tickets/:id/assign`
- `POST /api/tickets/:id/enqueue`
- `POST /api/tickets/:id/escalate`
- `GET /api/routing/queues/heatmap`
- `GET /api/routing/workload`


## Endpoints de automação operacional (MVP)

- `GET /api/automations`
- `POST /api/automations`
- `GET /api/automations/:id`
- `PUT /api/automations/:id`
- `DELETE /api/automations/:id`
- `PATCH /api/automations/:id/toggle`
- `POST /api/automations/:id/duplicate`
- `POST /api/automations/test`
- `POST /api/automations/:id/execute`
- `GET /api/automations/:id/logs`
- `GET /api/automations/logs`
- `POST /api/automations/validate-conflicts`
- `POST /api/automations/suggest`
- `POST /api/automations/simulate`


## Endpoints da torre de controle (MVP)

- `GET /api/supervisor/overview`
- `GET /api/supervisor/queues`
- `GET /api/supervisor/agents`
- `GET /api/supervisor/alerts`
- `GET /api/supervisor/ai`
- `GET /api/supervisor/automations`
- `POST /api/supervisor/redistribute`


## Endpoints SDR autônomo (MVP)

- `POST /api/leads/import`
- `POST /api/sdr/start`
- `GET /api/sdr/metrics`
- `GET /api/sdr/qualified`


## Endpoints de blueprint técnico

- `GET /api/platform/blueprint`
- `GET /api/platform/events`

## Estado atual

- Funciona em modo scaffold **sem banco externo**, usando stores em memória.
- `overview` e `ask-ai` já usam eventos ingeridos para calcular indicadores básicos.
- Roteamento usa triagem por regra + skill/capacidade com visão de heatmap e workload.
- Automações suportam prioridades, `stopOnMatch`, cooldown por ticket, execução testável e trilha de logs.
- Supervisor API consolida visão geral, estado de filas, capacidade de agentes, alertas e redistribuição rápida.
- SDR API suporta importação de leads, início de prospecção omnichannel, score automático e lista de leads qualificados.
- Platform API expõe blueprint modular orientado a eventos e catálogo de eventos canônicos para governança técnica.
- Quando conectado ao Supabase, os repositórios podem ser substituídos sem mudar os contratos HTTP.

## Exemplo de fluxo rápido

1. Envie eventos `conversation.created`, `ai.resolved_without_human` e `sla.first_response_breached` em `/api/events`.
2. Consulte `/api/reports/overview` com período (`dateFrom`, `dateTo`).
3. Pergunte em `/api/reports/ask-ai` para receber resumo + insights + recomendações sobre os dados do período.
4. Crie ticket em `/api/tickets` e valide distribuição inteligente por skill/capacidade.

## Guardrails já modelados

- Classificação de intenção analítica
- Planejamento de consulta por templates (`BuildSafeQueryService`)
- Catálogo de métricas permitidas (`METRICS_CATALOG`)

## Como evoluir

1. Conectar repositórios ao Supabase.
2. Implementar processor assíncrono de `event_store` para facts/dims.
3. Adicionar regras avançadas de SLA e transbordo de fila no módulo de routing.
4. Substituir resposta heurística do `GenerateAnswerService` por orquestração LLM + dados reais.
