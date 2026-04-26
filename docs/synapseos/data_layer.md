# Camada de Dados — Synapse OS Ecosystem

Documento de arquitetura da camada de persistência e troca de dados entre os
componentes do ecossistema. Define **quem é dono de cada entidade**, **quem
pode ler/escrever**, e **como os serviços se integram** sem virar bagunça.

Premissa: 1 VPS por cliente, single-host. Não é multi-tenant.

---

## 1. Componentes que tocam dados

| Serviço | Owns | Reads | Writes |
|---|---|---|---|
| **Chatwoot** (Rails) | Postgres `chatwoot_production` (todas tabelas) | seu DB, R2 (anexos) | seu DB, R2, dispara webhooks |
| **n8n** (workflows) | Postgres `n8n` (estado dos workflows, execuções) | Chatwoot API + (opcional) Postgres read-only do Chatwoot | Chatwoot API (POST messages), Avisa/Hyperflow API |
| **Synapseos Agentic** (panel) | Filesystem `clients/*.yaml` + S3 snapshots | n8n REST API, Chatwoot API (mirror) | n8n REST API (cria workflows), seus YAMLs |
| **Dexi Gateway** (ingestão) | Postgres `dexi_gateway` (LeadAudit) | Chatwoot API, Syonet API | Chatwoot API (Ponte A), Syonet API |
| **Cloudflare R2** | bucket `synapseos-<cliente>` | Chatwoot lê pra servir URLs | Chatwoot escreve anexos |
| **Syonet** (CRM externo) | DB do cliente, fora da nossa VPS | Gateway lê (futuro) | Gateway escreve via API |

---

## 2. Topologia de armazenamento

### 2.1 Postgres compartilhado, databases separados

Recomendação: **um único container Postgres** com 3 databases isolados.
Reduz RAM (1 instância em vez de 3) sem perder isolamento lógico.

```
postgres:5432
├── chatwoot_production      # Chatwoot fork (Rails + Synapseos custom)
├── n8n                      # n8n self-hosted (workflow state)
└── dexi_gateway             # Dexi Gateway (LeadAudit) — só se Gateway ativo
```

Synapseos Agentic não tem database — só YAMLs em disco + snapshots S3.

**Como criar os databases adicionais** (rodar no host após o Chatwoot subir):
```bash
docker compose -f docker-compose.prod.yml exec postgres \
  psql -U postgres -c "CREATE DATABASE n8n;"
docker compose -f docker-compose.prod.yml exec postgres \
  psql -U postgres -c "CREATE DATABASE dexi_gateway;"
```

### 2.2 Redis compartilhado, namespaces separados

Mesma ideia: 1 container Redis, namespaces lógicos por serviço.

```
redis:6379
├── DB 0    Chatwoot Sidekiq + ActionCable
├── DB 1    n8n queue (se rodar n8n em modo queue)
└── DB 2    Dexi Gateway Celery broker
```

### 2.3 Filesystem

| Path | Owner | Conteúdo |
|---|---|---|
| Volume Docker `storage` | Chatwoot | Vazio em prod (anexos vão pro R2) — só bootstrap inicial |
| Volume Docker `agentic_clients` | Agentic | `clients/<account_id>/<slug>.yaml` |
| Volume Docker `agentic_data` | Agentic | snapshots locais (fallback quando S3 não configurado) |
| Volume Docker `postgres_data` | Postgres | dados de todos os DBs |
| Volume Docker `redis_data` | Redis | persistência AOF |

### 2.4 Externo

| Recurso | Quando usar |
|---|---|
| Cloudflare R2 | **Sempre em prod** — anexos WhatsApp não cabem em volume Docker |
| Backblaze B2 (ou outro) | Backups off-site (rclone diário do pg_dump + tarball de YAMLs) |
| Syonet API | CRM do cliente — Gateway empurra leads, futuramente lê status |

---

## 3. Modelo de acesso (matriz read/write)

### 3.1 Postgres `chatwoot_production`

| Tabela | Quem lê | Quem escreve |
|---|---|---|
| `accounts`, `users`, `inboxes`, `conversations`, `messages`, `contacts` | Chatwoot, **n8n read-only**, Gateway via API | Chatwoot |
| `synapseos_pipeline_stages` | Chatwoot, **n8n read-only** (precisa saber stage atual do lead) | Chatwoot |
| `synapseos_leads`, `synapseos_deals`, `synapseos_crm_events` | Chatwoot, **n8n read-only** | Chatwoot |
| `agent_bots` (com `squadron_role`) | Chatwoot, Agentic via mirror | Chatwoot, Agentic Mirror service |
| `synapseos_agentic_deployment_logs` | Chatwoot Super Admin UI | Chatwoot, Job de sync de credencial |
| `installation_configs` | Chatwoot | Chatwoot Super Admin |

### 3.2 Como dar acesso ao n8n

**Pattern 1 — N8N usa apenas Chatwoot REST API** (recomendado pra MVP)

N8N nunca toca o Postgres direto. Tudo via:
- `POST /api/v1/accounts/{id}/conversations/{id}/messages` — enviar mensagem
- `GET  /api/v1/accounts/{id}/conversations/{id}` — ler estado da conversa
- `POST /api/v1/accounts/{id}/conversations/{id}/labels` — aplicar label
- `POST /api/v1/accounts/{id}/synapseos/leads/{id}/transition` — mover stage

Auth: access_token de um AgentBot dedicado (visível em Settings → Agent Bots).
Credencial no n8n: HTTP Header `api_access_token: <token>`.

**Pattern 2 — N8N usa Postgres read-only direto** (pra reports/queries complexas)

Quando o N8N precisa rodar query SQL agregada (ex: "quantos leads em `qualificado` mais de 7 dias"), API REST não cobre eficientemente. Aí cria-se um user Postgres read-only:

```sql
-- Rodar no Postgres do Chatwoot, uma vez por instalação:
CREATE USER n8n_reader WITH PASSWORD 'gerar via openssl rand -hex 32';

GRANT CONNECT ON DATABASE chatwoot_production TO n8n_reader;
GRANT USAGE ON SCHEMA public TO n8n_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO n8n_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO n8n_reader;

-- Especificamente bloquear acesso a credentials e tokens (defense in depth):
REVOKE SELECT ON access_tokens, installation_configs FROM n8n_reader;
```

No n8n: criar credencial **Postgres** com `host=postgres`, `port=5432`, `database=chatwoot_production`, `user=n8n_reader`, password do step acima.

⚠️ **Schema de Chatwoot não é estável** — upstream pode renomear colunas em qualquer release. Toda query do n8n direto no Postgres é débito técnico. Limitar a:
- Reports/dashboards (output usado por humano, fácil de recuperar de quebra)
- Casos onde a API REST é prohibitively slow

### 3.3 Como Agentic acessa dados Chatwoot

Agentic **não** acessa o Postgres do Chatwoot direto. Comunicação via:

1. **Chatwoot Mirror service** (`Synapseos::ChatwootMirror`, lib do core, já implementada) — quando o usuário salva/deploya um client no Agentic, o Mirror reflete em Chatwoot:
   - Atualiza `account.name`
   - Cria/atualiza `agent_bots` por slug
   - Detecta drift entre YAML e estado real

2. **Sync de credencial WhatsApp** — quando admin cria inbox WhatsApp no Chatwoot, dispara `Synapseos::SyncWhatsappCredentialJob` que chama o agentic em `POST /api/clients/{slug}/sync-whatsapp-credential`. Agentic cadastra a credencial no n8n via API.

Resumo: **Agentic e Chatwoot conversam via REST**, sem compartilhar DB.

### 3.4 Como Gateway acessa dados Chatwoot

- **Ponte A** (gateway → Chatwoot): cada lead aceito pelo Gateway dispara `POST /api/v1/accounts/{id}/contacts` + `POST /conversations` no Chatwoot via `ChatwootConnector`. Auth: access_token de bot dedicado.
- **Ponte B** (Chatwoot → gateway): webhook do Chatwoot configurado pra `POST /webhooks/chatwoot/{tenant_id}` quando conversa muda status. Gateway re-empurra pra Syonet via mesmo `external_id`.

Gateway tem seu próprio Postgres (`dexi_gateway` DB) só pra `LeadAudit` — independente do schema do Chatwoot.

---

## 4. Casos de uso concretos

### 4.1 N8N AgentBot quer saber em qual stage o lead está

**Fluxo:**
1. Mensagem entra no Chatwoot via WhatsApp.
2. Chatwoot dispara webhook `message_created` pro N8N (configurado em Settings → Integrations).
3. N8N node "HTTP Request" busca contexto:
   ```
   GET https://chatwoot.cliente.com.br/api/v1/accounts/{account_id}/contacts/{contact_id}/conversations
   Header: api_access_token=<bot_token>
   ```
4. Resposta inclui `additional_attributes.lead_id` e o agente busca:
   ```
   GET /api/v1/accounts/{id}/synapseos/leads/{lead_id}
   ```
   que retorna `pipeline_stage_id` + nome do stage.
5. N8N decide a próxima ação baseada no stage.

**Alternativa rápida** (se chamar a API várias vezes por mensagem virar gargalo):
N8N node "Postgres" com user `n8n_reader`:
```sql
SELECT s.slug, s.name, s.position
FROM synapseos_leads l
JOIN synapseos_pipeline_stages s ON s.id = l.pipeline_stage_id
WHERE l.id = $1;
```

### 4.2 Agent Metrics dashboard (atualmente 401)

**Por que está 401:** o controller `Api::V1::Accounts::Synapseos::AgentMetricsController` tem `before_action :ensure_administrator` que exige `Current.account_user.administrator?`. Se o user logado não é admin da account, retorna 401.

**Como resolver:** garantir que o user que carrega o dashboard é administrador na account. Em Super Admin → Account Users → sua linha → role = `administrator` (não `agent`).

Após isso, métricas refletem direto do DB:
- `Synapseos::AgentMetricsQuery.live` consulta `agent_bots` + `messages` + `conversations` da account.
- Frontend faz GET via `window.axios` (auth via cookie) — sem 401.

### 4.3 Pipeline CRM em tempo real

Já implementado:
- `Synapseos::LiveChannel` (ActionCable) faz broadcast quando lead muda de stage.
- Frontend `PipelinePage.vue` escuta e atualiza UI sem polling.
- Backend é canônico — `synapseos_pipeline_stages` + `synapseos_leads` no DB Chatwoot.

Pra N8N saber em real-time, dois caminhos:
- **Webhook + Polling**: N8N escuta webhook `conversation_updated` e busca stage via API quando relevante.
- **Postgres LISTEN/NOTIFY**: avançado, exige setup adicional. Não recomendado pra MVP.

### 4.4 Métricas históricas (relatórios mensais)

Cliente quer relatório mensal: leads recebidos, convertidos, por agente, por canal.

Pattern correto:
- **Chatwoot API** já tem `/api/v2/accounts/{id}/reports/agents` etc. que cobrem boa parte.
- Pro custom (segmentado por `squadron_role`, por exemplo), criar endpoint Rails dedicado em `app/controllers/api/v1/accounts/synapseos/reports_controller.rb`.
- N8N agenda job mensal: chama o endpoint, formata em PDF/email, envia.

NÃO replicar dados pra um data warehouse externo enquanto não houver volume que justifique (>10M conversations/mês). Postgres com índices nas colunas certas (`account_id`, `created_at`, `pipeline_stage_id`) atende.

---

## 5. Onde escrever — protocolos de integração

### 5.1 Quem pode escrever no `chatwoot_production`?
- Chatwoot Rails (web + worker)
- Mais ninguém. **N8N e Gateway escrevem via API REST** sempre.

### 5.2 Eventos saindo do Chatwoot
Webhooks configurados em Settings → Integrations → Webhooks:
- `conversation_created`, `conversation_status_changed`, `assignee_changed`
- `message_created`, `message_updated`
- `contact_created`, `contact_updated`

Cada webhook dispara em todos os endpoints registrados. URLs típicas:
- `https://n8n.cliente.com.br/webhook/synapseos-events`
- `https://gateway.cliente.com.br/webhooks/chatwoot/{tenant_id}`

### 5.3 Eventos saindo do n8n
N8N dispara HTTP requests pra Chatwoot quando o agente IA gera ação:
- Enviar mensagem: `POST /api/v1/accounts/{id}/conversations/{id}/messages`
- Resolver conversa: `POST /api/v1/accounts/{id}/conversations/{id}/toggle_status`
- Aplicar label: `POST /api/v1/accounts/{id}/conversations/{id}/labels`
- Mover lead de stage: `POST /api/v1/accounts/{id}/synapseos/leads/{lead_id}/transition`

Auth: access_token do AgentBot configurado no n8n como credencial.

### 5.4 Eventos saindo do Agentic
Agentic só escreve quando o usuário aciona deploy/save:
- Cria workflows no n8n (`POST /api/v1/workflows`)
- Atualiza `clients/<account_id>/<slug>.yaml` em disco + snapshot S3

Mirror pro Chatwoot acontece **do lado Chatwoot** (Rails service `ChatwootMirror` é chamado quando admin clica "Deploy" no Super Admin), não do agentic.

### 5.5 Eventos saindo do Gateway
- **Ponte A**: lead chegou pelo portal → cria contact + conversation no Chatwoot via API.
- **Sync Avisa**: dispara Syonet API com `eventType=ATENDIMENTO`/`FINALIZADO` baseado em status do Chatwoot.

---

## 6. Auth e credenciais

### 6.1 Tokens necessários por integração

| De | Pra | Tipo | Onde armazenar |
|---|---|---|---|
| n8n → Chatwoot | API REST | `api_access_token` de AgentBot | n8n Credentials Manager |
| n8n → Postgres Chatwoot | SQL | user `n8n_reader` + senha | n8n Credentials Manager |
| Agentic → n8n | API REST | `X-N8N-API-KEY` | env var no Agentic |
| Agentic → Chatwoot | API REST (Mirror reverso, futuro) | `api_access_token` admin | env var no Agentic |
| Chatwoot → Agentic | API REST (CRUD super_admin) | Basic Auth `admin:password` | InstallationConfig do Chatwoot |
| Gateway → Chatwoot | API REST (Ponte A) | `api_access_token` de AgentBot | env var do Gateway |
| Gateway → Syonet | API REST | Basic Auth (`SYONET_USER`/`SYONET_PASSWORD`) | env var do Gateway |
| Chatwoot → Gateway | webhook | HMAC opcional | env var do Gateway (`CHATWOOT_WEBHOOK_SECRET`) |
| App → R2 | S3 API | Access Key + Secret | env var do Chatwoot (`STORAGE_*`) |

### 6.2 Rotação de credenciais

Quando rotacionar:
- **AgentBot tokens** — só rotaciona se vazar. Caso contrário, validade indefinida.
- **n8n_reader senha** — anual ou após incidente.
- **R2 keys** — anual.
- **Backblaze backup keys** — anual.

Roteiro de rotação:
1. Gerar nova credencial (no painel do serviço dono).
2. Atualizar env var/config no consumidor.
3. Restart do consumidor.
4. Confirmar funcionamento.
5. Revogar credencial antiga.

---

## 7. Migrations e evolução de schema

### 7.1 Quem é dono dos schemas

| Schema | Owner | Migrations file path |
|---|---|---|
| `chatwoot_production` | Chatwoot (Rails) | `db/migrate/*.rb` |
| `n8n` | n8n upstream | gerenciado pelo container |
| `dexi_gateway` | Gateway (SQLAlchemy) | `services/dexi-gateway/src/dexi_gateway/db.py` (`create_all` no boot) |

### 7.2 Tabelas custom do Chatwoot (Synapseos)

Tabelas que adicionamos sobre a base do upstream:

```
agent_bots                              -- coluna squadron_role adicionada
synapseos_pipeline_stages               -- 7 SPIN stages default
synapseos_leads                         -- leads com pipeline_stage_id
synapseos_deals                         -- valores fechados (won/lost)
synapseos_crm_events                    -- eventos timeline (agendar, qualificar, etc.)
synapseos_agentic_deployment_logs       -- audit log do Super Admin → Agentic
```

Quando upstream Chatwoot ficar major upgrade, conferir conflito com nossas migrations.

### 7.3 Compatibilidade entre serviços

Contratos a respeitar:
- **`agent_bots.squadron_role`** — valores `%w[alice iza luis otto fernanda angela vitor natalia]`. Adicionar valor novo aqui exige update do `Synapseos::AgentResolver::SLUGS` E do agentic `AGENTS` registry.
- **Chatwoot REST API** — n8n e Gateway dependem dos endpoints `/conversations`, `/messages`, `/synapseos/*`. Não renomear/remover sem coordenar.
- **Webhook payloads** — `event`, `conversation.id`, `conversation.status`, `assignee_id`, `message.content`, `message.message_type`. Estável upstream.

---

## 8. Backups e durabilidade

| Camada | Backup strategy | RPO | RTO |
|---|---|---|---|
| Postgres (todos DBs) | `pg_dump` diário 03:00 → R2/B2 off-site, retenção 30 dias | 24h | ~30min (restore manual) |
| YAMLs Agentic | tar diário → off-site + snapshots S3 a cada save | 24h (off-site) / instantâneo (S3) | ~5min |
| Anexos R2 | já é durable (3-region replication Cloudflare) | 0 | 0 |
| Logs | volátil (50m × 5 rotação) | N/A | N/A |

Restore de Postgres com múltiplos DBs:
```bash
gunzip -c pg_2026-04-26.sql.gz | docker compose exec -T postgres psql -U postgres
```
(O dump inclui `\connect database_name` switches automaticamente.)

---

## 9. Performance & escala

### 9.1 Limites do single-host

Conta de pão:
- 100 agentes humanos + 7 AgentBots + 50.000 conversações/mês = ~16k mensagens/dia.
- Postgres com índices certos: <50ms p95 nas queries do Chatwoot.
- Redis Sidekiq fila <1000 jobs em backlog em horário de pico.
- 4 vCPU / 8 GB confortável até 2× esse volume.

Quando escalar:
- **>200 agentes ou >100k conversações/mês**: separar Postgres em VPS própria, mexer em `POSTGRES_HOST` no `.env`.
- **>1000 mensagens/min em pico**: Sidekiq replicas (worker scaling no compose).
- **>50 GB de anexos/mês**: já vai pro R2, não preocupa.

### 9.2 Queries críticas a indexar

Já no schema atual:
- `synapseos_pipeline_stages(account_id, slug)` UNIQUE
- `synapseos_leads(account_id, pipeline_stage_id)`
- `synapseos_agentic_deployment_logs(slug)`
- `agent_bots(account_id, squadron_role)`

Conferir antes de feature nova: rodar `EXPLAIN ANALYZE` nas queries adicionadas.

---

## 10. Roadmap

### Curto prazo (esta entrega)
- ✅ Fix do 401 nas Synapseos pages (axios global) — feito
- ✅ Storage R2 documentado — feito
- 🔲 **Garantir user admin** — Lorrayne precisa estar como `administrator` em account 1 pra ver Agent Metrics
- 🔲 Criar databases `n8n` e `dexi_gateway` no Postgres compartilhado quando provisionar primeira VPS Interlivre

### Médio prazo (próximas 2-4 semanas)
- 🔲 Criar user `n8n_reader` no Postgres com SELECT-only nas tabelas relevantes
- 🔲 Documentar contratos da REST API do Chatwoot que N8N depende (versionar com OpenAPI/Swagger)
- 🔲 Endpoint `/api/v1/accounts/{id}/synapseos/reports/*` pra dashboards customizados
- 🔲 Snapshots S3 do Agentic em produção (criar bucket `synapseos-agentic-snapshots-<cliente>`)

### Longo prazo (3+ meses)
- 🔲 Avaliar migração pra Postgres logical replication se cliente quer relatórios isolados
- 🔲 Considerar Redis Streams pra event bus se número de webhooks crescer (atualmente direto HTTP é suficiente)
- 🔲 Métricas em tempo real via dashboard externo (Grafana lendo direto Postgres replicado)

---

## 11. Quick reference por papel

### Lorrayne (precisa criar/manter dados)
- **Pipeline CRM** → painel Chatwoot `/synapseos/pipeline` (UI cobre 100%)
- **Métricas** → `/agent_metrics` no painel (precisa user admin)
- **Bots/Agentes** → Settings → Agent Bots no Chatwoot
- **Templates pipeline** → botão "Templates" na página Pipeline
- **Provisionar agente novo** → Super Admin → Synapse Agents (proxy CRUD do agentic)

### N8N developer
- **Auth**: criar AgentBot no Chatwoot, copiar `access_token`, cadastrar como credencial HTTP no n8n
- **Webhook URL**: configurar no Chatwoot apontando pro endpoint do n8n
- **Read-only DB** (avançado): pedir senha do `n8n_reader` ao DevOps
- **Docs API**: https://www.chatwoot.com/developers/api

### DevOps
- **DB principal**: container `postgres` na rede do compose, vol `postgres_data`
- **Criar DB n8n**: `docker compose exec postgres psql -U postgres -c "CREATE DATABASE n8n;"`
- **Backup**: `scripts/backup_offsite.sh` (cron diário)
- **Restore**: instructions na §8
- **R2 setup**: `ecosystem_handoff.md` §4.4
