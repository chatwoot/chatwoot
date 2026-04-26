# Dexi Gateway – MVP

Serviço HTTPS + worker que recebe leads multi-canal (Meta Lead Ads, Google Lead Forms,
formulário de site, WhatsApp Cloud), qualifica com LLM e **injeta o lead no CRM Syonet
via `POST /api/lead`** respeitando todas as particularidades do PDF oficial (Basic Auth,
ISO-8859-1, `event.leadInfo.gclid` case-sensitive, `daysToUpdateOpenEvent`).

Escopo deste MVP: **Gateway + Syonet Connector** (Onda 1 do dossiê de arquitetura).
Todo o caminho rodável em **modo mock** sem credenciais reais.

## Arquitetura

```
Canais → FastAPI (webhooks) → Redis (fila Celery) → Worker (LLM qualify + Syonet Connector) → Postgres (auditoria)
                                                                    ↘ Syonet mock ASGI (para testes)
```

Componentes:

- `dexi_gateway.app` – FastAPI com 4 webhooks (`/webhooks/meta/{tenant_id}`, `/google/...`, `/site/...`, `/whatsapp/...`).
- `dexi_gateway.adapters.*` – normalizam cada canal em `NormalizedLead`.
- `dexi_gateway.dedup` – supressão por `tenant_id + external_id` em Redis (janela configurável).
- `dexi_gateway.worker` – Celery task `dexi.process_lead`.
- `dexi_gateway.llm.qualifier` – LiteLLM multi-provider + fallback mock determinístico.
- `dexi_gateway.syonet_connector` – cliente HTTP que implementa `POST /api/lead` conforme PDF.
- `dexi_gateway.mocks.syonet_mock` – servidor FastAPI que finge ser um tenant Syonet.

## Rodar local

```bash
cp .env.example .env
docker compose up --build
# API:        http://localhost:8080
# Syonet mock: http://localhost:9090
```

Smoke test via `curl`:

```bash
curl -X POST http://localhost:8080/webhooks/site/tenant-a \
  -H 'Content-Type: application/json' \
  -d '{
    "nome": "Maria",
    "email": "maria@example.com",
    "telefone": "+5541988888888",
    "marca": "Jeep",
    "modelo": "Compass",
    "gclid": "gclid-abc"
  }'
# => {"status":"accepted","lead_id":"<uuid>"}
```

## Testes

```bash
pip install -e ".[dev]"
pytest -q
```

## Design decisions (ADRs resumidos)

1. **Celery + Redis** em vez de RQ para ganhar retries por tipo de erro + backoff nativo.
2. **ISO-8859-1 end-to-end no Syonet Connector** – request e response. Parsers em UTF-8 quebram em nomes com acento.
3. **Dedup em Redis (não em Postgres)** – TTL nativo, zero fricção.
4. **LiteLLM** abstrai provider (OpenAI, Gemini, Azure, Anthropic) via env `LLM_PROVIDER_MODEL`.
5. **Mock Syonet é um app ASGI próprio** – permite `ASGITransport` em testes E2E sem subir processo.
6. **Auditoria em tabela única `lead_audit`** com `status` evolutivo (`received` → `qualified` → `syonet_sent` / `syonet_error`).

## Bridge com Chatwoot (opt-in por cliente)

Cliente que usa o Synapse OS (Chatwoot fork) pode habilitar duas pontes via `.env`:

**Ponte A — gateway → Chatwoot**: cada lead aceito vira contato + conversa
numa inbox do Chatwoot. A criação da conversa dispara automaticamente o
webhook `conversation_created`, que é onde o N8N AgentBot escuta pra iniciar
o fluxo conversacional.

**Ponte B — Chatwoot → gateway → Syonet**: o Chatwoot empurra eventos de
status pra `POST /webhooks/chatwoot/{tenant_id}`. O gateway mapeia
`status: open` → `ATENDIMENTO` e `status: resolved` → `FINALIZADO`, e reenvia
ao Syonet com o mesmo `externalId` (o `daysToUpdateOpenEvent` permite
atualizar o evento aberto sem duplicar lead).

Setup:

1. No `.env` do gateway:
   ```
   CHATWOOT_ENABLED=true
   CHATWOOT_BASE_URL=https://chatwoot.cliente.com.br
   CHATWOOT_API_TOKEN=<access_token de um agente/bot admin>
   CHATWOOT_ACCOUNT_ID=1
   CHATWOOT_DEFAULT_INBOX_ID=<inbox onde os leads de portal entram>
   CHATWOOT_WEBHOOK_SECRET=<segredo HMAC>
   ```

2. No Chatwoot do cliente: Settings → Integrations → Webhooks → URL
   `https://gateway.cliente/webhooks/chatwoot/{tenant_id}`. O Chatwoot não
   manda `X-Chatwoot-Signature` nativamente — em produção, restringir esse
   path a IPs do Chatwoot via proxy reverso (Caddy `@chatwoot remote_ip ...`).

Cliente que **não** habilita as pontes roda só gateway → Syonet, sem
qualquer interação com Chatwoot.

## O que NÃO está neste MVP (por escopo explícito)

- Plugin NBSi Auto-Connector (Onda 3 do dossiê de arquitetura).
- Webhook reverso Syonet → Dexi (depende de liberação privada por tenant).
- Agentes Ângela e Vitor (dependem de NBSi).
- LDM completo na Azure (neste MVP: auditoria em Postgres local).

## Próximos passos sugeridos

1. Substituir o mock LLM pela chamada real Gemini/GPT-4o/Claude.
2. Adicionar Meta Graph API fetch para expandir `leadgen_id` em produção.
3. Migrar auditoria para o LDM na Azure (Data Lake + Delta).
4. Adicionar endpoints privados Syonet quando liberados: `GET /api/lead?updatedSince=...`, webhook reverso.
5. Quando o upstream Chatwoot suportar HMAC nativo no Webhook Integration, trocar o IP-allowlist por verificação criptográfica.
