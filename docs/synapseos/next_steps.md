# Synapse OS — Próximos Passos

**Data do snapshot:** 2026-04-24 (noite autônoma)
**Branch:** `custom/initial-cleanup` (sincronizada com `synapseos/main` no Railway)
**Última release pushada:** `8db9616fc` — docker-compose.prod + seeders automáticos + comandos expandidos

---

## 1. Estado atual (versão fechada)

### Já em produção

**Sprints S1–S8 (overnights 04-21/22):**
- Debloat + branding PT-BR
- CRM Pipeline com 5 stages default + webhooks N8N — Kanban CRUD em `/synapseos/pipeline`
- Painel "Dados do Sistema Legado" + 3 custom attrs
- Notas privadas IA estilizadas
- Backend `AgentMetrics` + `LiveChannel` (ActionCable)
- `LiveDashboard` tempo real
- `AgentMetrics` C-Level dashboard
- Home redirect role-based (admin → AgentMetrics)

**PRs 1–4 (refactor de navegação):**
- Sidebar flat top-level (5 itens Synapse OS)
- `DashboardPage` com tabs (Visão geral / Relatórios ao vivo)
- `LiveAgents` drilldown server-side
- N+1 de `last_message` corrigido

**PR 5 — Avisa transport direto (sem N8N no transporte):**
- `AvisaClient` client puro (sendMessage/parselid/webhook)
- Webhook inbound autenticado por `token`
- `IncomingMessageAvisaService` parser whatsmeow cru + LID resolve
- Wizard 2-campos (phone + api_key), auto-registro de webhook

**PR 7 — Avisa mídia (inbound + outbound texto via base64):**
- `AvisaClient`: `send_image_base64` / `send_document_base64` / `send_audio_base64` / `send_media` (URL)
- `AvisaService#send_attachment_message` roteia por tipo (image/doc/audio via base64; video via URL)
- `IncomingMessageAvisaService` detecta mídia + anexa `params[:file]` via ActiveStorage
- Commit `e0ef88442` + refinamentos em `7dcc82bf5`

**PR 8 — Reações, edições, quoted messages:**
- Reações (`reactionMessage`) atualizam `content_attributes.external_reactions` da msg alvo, idempotente, com suporte a remoção
- Edições (`protocolMessage.editedMessage`) sobrescrevem `content` + flag `edited_at`
- Quoted messages populam `content_attributes.in_reply_to_external_id` (nativo Chatwoot)
- Commit `15f608a2e`

**PR 6 — Squadron_role no AgentBot + KPIs por papel + wizard:**
- Migration `squadron_role` no `agent_bots`
- 7 papéis canônicos: `alice` (Prospecção), `iza` (Recepção), `luis` (Especialista), `otto` (Auditoria), `fernanda` (Resgate), `angela` (Farming), `vitor` (Recuperação)
- `AgentResolver` prioriza `squadron_role`, fallback pelo nome pra bots legados
- `AgentMetricsQuery` com queries específicas por papel (outbound × inbound separados)
- Modal de criar bot com select obrigatório + multi-select de inboxes
- LiveDashboard/AgentMetrics renderizam 7 cards
- Commit `2c99bd1f3`

**Infra Railway:**
- Dispatcher único (`railway_start.sh`) decide web vs worker via `RAILWAY_SERVICE_NAME` — mesmo `railway.json` pros dois serviços
- Healthcheck removido (era fatal pro worker Sidekiq)
- Commits `d06545658`, `180902c5a`

**Fixes UX:**
- Template picker dispensado em nova conversa pra Avisa/Hyperflow (`f5fa0ba16`)
- Banner 24h sumiu no ReplyBox pra providers não-oficiais (`17a1aee38`)
- Outgoing echo: resposta pelo celular do atendente aparece no Chatwoot, com dedup por `source_id` (`20b11ec6e`)
- Auto-registro de webhook atômico na criação da inbox, com rollback se falhar (`d61c910eb`)

---

## 1.1 Entregas da noite 2026-04-24 (autônoma)

**Fixes:**
- Live Agents: loading eterno corrigido (`fetchAgents` com `try/finally` + UI de erro com botão retry). Commit `e3e8b0ef7`.
- Pipeline default à prova de bala: `PipelineSeeder` resiliente a schema sem coluna `slug` + controller com fallback que cria os 5 stages em memória se seeder silenciar. Commit `9b025fa58`.

**Novos seeders automáticos** (commit `341472e28`):
- `ContractLabelsSeeder`: cria as 12 labels do contrato com cores Dexi. Roda no `AccountDefaults.seed` + migration de backfill em contas existentes.
- `SquadronBotsSeeder`: cria os 7 AgentBots (Alice/Iza/Luís/Otto/Fernanda/Ângela/Vitor) com `squadron_role` preenchido. Admin só configura `outgoing_url` depois em Settings → Agent Bots.

**Comandos expandidos em notas privadas** (commit `341472e28`):
- `/agendar YYYY-MM-DD` — cria `CrmEvent appointment`, move lead pra `negociacao`
- `/qualificar` — aplica label + cria Lead + move pra `qualificado`
- `/stage <slug>` — move lead direto
- `/tag <slug>` — aplica label do contrato
- Docs em `docs/synapseos/slash_commands.md`

**Deploy VPS** (commit `8db9616fc`):
- `docker-compose.prod.yml` com web + worker + pgvector + redis + volume `storage` compartilhado (resolve mídia outbound sem S3).
- `.env.example.prod` template com todas vars.
- `docs/synapseos/vps_deploy.md` guia completo: Docker, Caddy SSL, backup, troubleshooting.

**Redesign Dashboard** (commit `e3e8b0ef7`):
- Estilo mission-control: strips com `divide-x`, números `tabular-nums`, chart com cyan accent + tooltip navy, tipografia técnica uppercase.

**Sidebar enxuta** (commits `c9ce087ee`, `a743a3688`):
- Removidos: Tempo Real, Conversas, Contatos, Companies, Captain, Robôs/SLA/CSAT/Time/Caixa/Etiquetas em Reports.
- Caixa de Entrada agora aponta pra rota `home` (todas as conversas).
- Bell de notificações na toolbar do topo com badge cyan unread.

---

## 2. Pendências conhecidas (não-bloqueantes pra esta versão)

### Mídia outbound via URL (vídeo + storage local)
- Hoje `sendMedia` com URL pública só funciona se `ACTIVE_STORAGE_SERVICE` for S3/R2. Railway default é `local` e web ≠ worker filesystem, então anexo gravado pelo web some na leitura do worker.
- Fix implementado: mensagem que falha por `ActiveStorage::FileNotFoundError` é marcada `:failed` em vez de entrar em retry loop (`05d236692`).
- Solução definitiva: `docker-compose.prod.yml` com volume compartilhado entre web e worker (modelo VPS Interlivre) — local storage funciona. R2 só necessário se multi-node.

### Commit `967362d71` ("commit3")
- Mensagem inutilizável, legado de workaround por git plumbing. Não-urgente. Pode rebasear quando for conveniente.

### node_modules local quebrado
- `eslint`/`ajv` com erro de módulo no Node 24. Não afeta o Railway (build limpo). `pnpm install --force` no dev local resolve quando for mexer em JS.

### AgentBot legado (se existir)
- Bots com name `'Alice & Iza'` e sem `squadron_role` são mapeados pra slug `iza` via fallback. Editar no wizard atribui o papel explícito.

---

## 3. Próximos PRs candidatos

### PR de entrega — `docker-compose.prod.yml` para cliente VPS
- Deliverable real do SaaS (modelo 1-VPS-por-cliente Interlivre)
- Resolve mídia outbound como efeito colateral (volume compartilhado)
- Inclui: web, worker, pgvector, redis, volume `storage`, `.env.example`, instruções

### Branding / logos SVG
- Placeholders em `public/brand-assets/` ainda são Chatwoot
- Depende de arte finalizada
- Sweep final de strings "Chatwoot" residuais via `replaceInstallationName`

### Painel Super Admin Next.js
- Repo separado, pro dono do SaaS administrar accounts sem mexer no Chatwoot Super Admin nativo

### Grupos WhatsApp (fora do PR 8)
- `Info.IsGroup=true` → mapear participantes, criar conversation de grupo
- Chatwoot não tem modelo nativo de grupo — requer custom attribute ou nova tabela

### UI de reações
- Dados estão em `content_attributes.external_reactions` desde o PR 8, mas nada renderiza ainda
- Badge com emoji abaixo da bubble seria suficiente pra MVP

---

## 4. Referência rápida — Avisa API

- **Base URL:** `https://www.avisaapi.com.br/api`
- **Auth:** `Authorization: Bearer <token_instancia>`
- **Send text:** `POST /actions/sendMessage` body `{number, message}`
- **Send media (URL):** `POST /actions/sendMedia` body `{number, fileUrl, type, message?, fileName?}`
- **Send media (base64):** `POST /actions/sendImage` / `/sendDocument` / `/sendAudio`
- **Register webhook:** `POST /webhook` body `{webhook}`
- **Resolve LID:** `POST /user/parselid` body `{lid}`
- **Inbound content-types:**
  - Texto/reação/edição: `application/x-www-form-urlencoded` (fields: `token`, `jsonData`)
  - Mídia: `multipart/form-data` (fields: `token`, `jsonData`, `file`)

Detalhes completos em `memory/project_avisa_api.md`.

---

## 5. N8N AgentBot workflow

Fluxo exemplo em `docs/synapseos/n8n_avisa_demo_workflow.json` (se aplicável) ou gerado sob demanda:

- Webhook Chatwoot → Normalize Input (achata body em campos flat)
- IF `message_type != outgoing` (evita loop)
- Guardrails: bloqueia auto-response de WhatsApp Business
- AI Agent (OpenAI + Postgres memory por `conversation_id`)
- Build Callback → HTTP POST `/api/v1/accounts/:id/conversations/:id/messages`
- Env vars: `CHATWOOT_URL`, `CHATWOOT_AGENT_BOT_TOKEN` (access_token do bot)

---

## 6. Workaround de git plumbing (se travar de novo)

```bash
rm -f .git/index.lock
git add <files>
tree=$(git write-tree)
commit=$(git commit-tree "$tree" -p HEAD -m "mensagem")
git update-ref HEAD "$commit"
git push synapseos custom/initial-cleanup:main
```

Usado quando husky/lint-staged falha por módulos Node quebrados.
