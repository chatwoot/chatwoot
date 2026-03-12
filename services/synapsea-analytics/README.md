# Synapsea Analytics Service (Scaffold)

Backend Node.js scaffold para o módulo de relatórios estruturados + relatórios dinâmicos com IA do Synapsea Connect.

## Estrutura

- `src/modules/events`: ingestão de eventos operacionais (`event_store` pipeline)
- `src/modules/reports`: endpoints fixos de dashboards
- `src/modules/ai-reports`: camada "pergunte à IA" com guardrails
- `src/lib/metricsCatalog.ts`: catálogo oficial de métricas permitidas

## Endpoints iniciais

- `GET /health`
- `POST /api/events`
- `GET /api/reports/overview`
- `POST /api/reports/ask-ai`

## Guardrails já modelados

- Classificação de intenção analítica
- Planejamento de consulta por templates (`BuildSafeQueryService`)
- Catálogo de métricas permitidas (`METRICS_CATALOG`)

## Como evoluir

1. Conectar repositórios ao Supabase.
2. Implementar processor assíncrono de `event_store` para facts/dims.
3. Adicionar mais endpoints fixos (`/slas`, `/agents`, `/leads`, `/ai-usage`).
4. Substituir resposta mock do `GenerateAnswerService` por orquestração LLM + dados reais.
