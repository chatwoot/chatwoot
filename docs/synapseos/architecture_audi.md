# Arquitetura SynapseOS — visão de sistema com foco no tenant Audi

**Status:** Aceito (documenta o estado em produção)
**Data:** 2026-06-02
**Escopo:** Fork Chatwoot (`synapseos/`) + `synapseos-agentic` (n8n + painel Flask) + infra VPS, com foco no piloto **Audi Center Uberlândia** (account_id=2).

---

## 1. Contexto

O SynapseOS é um **SDR/CRM de vendas conversacional sobre WhatsApp**, montado como uma camada por cima do Chatwoot OSS. Não é um produto único: é um ecossistema distribuído por **três planos** que se comunicam por webhooks assinados e APIs REST.

O piloto Audi é o primeiro tenant real em produção: a persona **Elisa** atende leads de uma concessionária Audi via WhatsApp, qualifica, recomenda modelos, agenda visita e faz handoff para consultor humano — com todo o histórico espelhado no painel Chatwoot e o funil de vendas modelado em 8 estágios.

### Forças em jogo
- **Multi-tenant por design, single-tenant na prática.** A arquitetura suporta N clientes (templates de persona, `clients/*.yaml`), mas só o Audi está vivo. Decisões foram calibradas pra estabilidade do piloto, não pra escala.
- **LLM teimosa.** Boa parte da complexidade existe pra forçar comportamento determinístico em cima de um agente não-determinístico (regras no prompt > tools, handlers post-hoc, gates).
- **Deploy destrutivo.** O painel restaura workflows a partir do template base a cada deploy — o que motivou o padrão `post_deploy.py` (ADR-001 abaixo).
- **Telefone BR.** O 9º dígito do celular é a fonte número 1 de bugs de identidade (conversas rachadas, contatos duplicados).

---

## 2. Topologia de alto nível

```
   WhatsApp do cliente
        │
        ▼
   ┌─────────┐   inbound (token)        ┌──────────────────────────┐
   │  Avisa  │ ───────────────────────► │  Chatwoot fork (Rails)   │
   │  API    │ ◄─────────────────────── │  account_id=2, inbox_id=2│
   └─────────┘   outbound (HTTP)        │  AgentBot 15 = Elisa     │
        ▲                               │  camada synapseos/       │
        │                               └──────────────────────────┘
        │ envia resposta                      ▲          │
        │                                     │ log       │ webhook deal_won/lost
        │                              (display_id)        │ (HMAC X-Synapseos-Signature)
   ┌────┴───────────────────────────────────┐│          ▼
   │            n8n (orquestração)           ││   N8N_WEBHOOK_ANGELA/FERNANDA
   │  WF01 disparador → WF02 central →       ││
   │  WF03 input → WF04 SDR → WF05 estoque   │┘
   │  WF07 tools → WF08 follow-up → WF99 err │
   │  + sub-wfs (knowledge_query, log_out…)  │
   └─────────────────┬───────────────────────┘
                     │                    ▲
                     ▼                    │
              ┌──────────┐         ┌──────────────┐
              │ Postgres │         │  Slack (Dexi)│
              │  Audi    │         │ #alertas-vendas
              │ leads,   │         │ #incidents… │
              │ memoria… │         └──────────────┘
              └──────────┘

   ┌──────────────────────────────────────────────┐
   │  Painel Flask/FastAPI (synapseos-agentic)     │
   │  POST /api/clients/audi/deploy (LOCKED)       │
   │  → renderiza templates → n8n API              │
   │  scripts/audi/post_deploy.py re-aplica tudo   │
   └──────────────────────────────────────────────┘

   Infra: VPS 158.69.63.140 · Docker Swarm + Traefik
   chat.dexidigital.com.br (Chatwoot) · painel.dexidigital.com.br (painel)
   app5.dexidigital.com.br (n8n)
```

### Os três planos

| Plano | Repo / local | Responsabilidade | Fonte da verdade |
|---|---|---|---|
| **Aplicação** | `chatwoot` fork, camada `app/**/synapseos/` | CRM (leads, deals, stages, crm_events), inbox WhatsApp, dashboard, webhooks in/out | Código Rails versionado |
| **Orquestração** | n8n (live na VPS) | Lógica conversacional da Elisa, follow-up, knowledge, handoff | n8n UI + `scripts/audi/post_deploy.py` |
| **Controle** | `synapseos-agentic` backend FastAPI | Deploy/onboarding de tenants, render de templates, snapshots | `clients/*.yaml` + `templates/` |

> **Insight central:** a "fonte da verdade" é **fragmentada por categoria**, não por repo. Prompt → YAML; mensagem hardcoded → `post_deploy.py`; estrutura de workflow → n8n UI + snapshot em `reference/audi/`; credencial → n8n UI; schema DB → `deploy/sql/`. Isso é o coração da ADR-001 e a causa raiz da maior parte da complexidade operacional.

---

## 3. Camada `synapseos/` no Chatwoot (plano de aplicação)

### 3.1 Modelo de domínio CRM

```
Account (2) ─┬─ PipelineStage [8 stages: aguardando_atendimento … encerrado]
             │
             ├─ Lead ──── belongs_to conversation, contact, assignee, pipeline_stage
             │     │      status: open|qualified|disqualified|converted
             │     └─ has_many Deal (status: pending|won|lost, amount BRL)
             │
             └─ CrmEvent (append-only audit: lead_created, deal_won, bot_takeover,
                          human_rescue, appointment, lead_blocked, …)
```

- **`Lead`** auto-sincroniza o `Deal` relacionado pra `won`/`lost` quando a `pipeline_stage` muda pra um estágio won/lost. Emite `CrmEvent`.
- **`PipelineStage`** tem `slug` único por conta + `stage_type` (inbound/open/working/won/lost/custom). Templates definidos em `Synapseos::PipelineTemplates` (6 verticais: spin_generico, concessionaria_online, **audi_sdr**, premium_luxo, hospital, oncologia).
- **`CrmEvent`** é o ledger imutável — base do dashboard C-Level e da timeline.

### 3.2 Pipeline Audi (template `audi_sdr`, 8 stages)

| # | slug | tipo | quem move |
|---|---|---|---|
| 1 | aguardando_atendimento | inbound | sistema (lead novo) |
| 2 | em_atendimento | open | n8n (seed log_outgoing + handler WF04) |
| 3 | futuro | open | **manual** (consultor) |
| 4 | aguardando_visita | working | n8n (handoff vendedor/consultor) |
| 5 | veiculo_em_espera | working | **manual** |
| 6 | negociacao | working | **manual** |
| 7 | venda | won | **manual** |
| 8 | encerrado | lost | n8n (recusa explícita) |

> **Decisão de produto (Sandro):** estágios downstream (negociação→venda) são **fonte de verdade do consultor humano** — automação nunca os infere. A Elisa/n8n só governa o topo do funil (1,2,4,8).

### 3.3 Integração inbound (WhatsApp → Chatwoot)

Dois controllers de webhook, dois mecanismos de auth:

| Controller | Rota | Auth | Parser |
|---|---|---|---|
| `webhooks/avisa_controller` | `POST /webhooks/avisa` | `params[:token]` == `provider_config['api_key']` | `IncomingMessageAvisaService` (formato whatsmeow/Baileys) |
| `webhooks/hyperflow_controller` | `GET/POST /webhooks/hyperflow/:phone` | HMAC `X-Synapseos-Signature` vs `webhook_secret` | `IncomingMessageHyperflowService` (formato Meta Cloud API) |

O **Audi usa Avisa** (direto, sem n8n no caminho inbound). O `IncomingMessageAvisaService`:
- Resolve `@lid` (JID anônimo) → JID real via `AvisaClient.parse_lid`.
- **`normalize_br_phone`**: `55 + DDD(2) + 8 dígitos` → insere `9` → `55 + DDD + 9 + 8`. Canonical = **COM 9**. (commit `6c575171c8`)
- Trata texto, mídia (imagem/vídeo/áudio/doc/sticker), reactions, edits, quoted, e echo de outgoing (`IsFromMe=true`).

### 3.4 Integração outbound (Chatwoot → n8n)

`Synapseos::WebhookDeliveryJob` (async, retry exponencial 5x) dispara em transição won/lost via `PipelineTransitionService`:
- `deal_won` → `N8N_WEBHOOK_ANGELA_URL`
- `deal_lost` → `N8N_WEBHOOK_FERNANDA_URL`
- Assinado HMAC-SHA256 com `SYNAPSEOS_WEBHOOK_SECRET` no header `X-Synapseos-Signature`.

### 3.5 Operação por humano (slash commands em notas privadas)

`SynapseosListener` interpreta comandos em notas privadas da conversa:
`/ganhei [valor]`, `/perdi [valor]`, `/agendar YYYY-MM-DD`, `/qualificar`, `/stage <slug>`, `/tag <slug>`. Transições de assignee Bot→User geram `bot_takeover`; User→Bot geram `human_rescue`. Broadcast real-time via `Synapseos::LiveChannel` (`synapseos_live_<account_id>`).

---

## 4. Plano de orquestração (n8n) — o cérebro da Elisa

Workflows live (IDs em produção, geridos por `post_deploy.py`):

| WF | ID | Função |
|---|---|---|
| WF01 | `XSXPAF1pbLs7lmmU` | Disparador — primeiro contato outbound + batch de backlog |
| WF02 | `noMDismFYi0cwh0c` | Sistema Central — recebe inbound, buffer/debounce 8s, split de mensagens, gate de intervenção humana |
| WF03 | `K5tnxMMhQfXBOqUY` | Tratamento input — download/parse de áudio, imagem, documento |
| WF04 | `HgoLpYyFxoUEJU0s` | Central Agentes — SDR (system prompt Elisa) + classificador de estado + handoff handler |
| WF05 | `OLmhIcJ5tbL3gpq1` | Agente Estoque — recomendação de modelos via Postgres knowledge |
| WF07 | `UgpwZWwYgPAkPN6B` | Tools Agente — handoff, encerrar, agendar + alertas Slack |
| WF08 | `KPjKu1Z6QkXntazO` | Follow-up — cadência 5 estágios + FU_HOT (lead quente) |
| WF99 | `S0GMMvklQgDdND7C` | Error handler → Slack #incidents |
| log_outgoing | `gKmHf5ueWTA9Fyjl` | Loga reply da Elisa no Chatwoot (cria conv no 1º contato; seed lead em em_atendimento) |
| noop | — | `outgoing_url` do AgentBot 15 aponta aqui (evita re-dispatch duplicado pelo Chatwoot) |
| + sub-wfs | dinâmicos | knowledge_query, reset_lead, set_gallery, block_lead, seed_lead, followup_tick, etc. |

### Padrões anti-teimosia (LLM determinismo)
- **Regras no prompt** em vez de forçar tools (a LLM ignora tools com frequência).
- **Handoff handler post-hoc** (WF04): se a LLM não chamar a tool de handoff, um Code node infere pelo output e força o webhook + alerta Slack.
- **Pre-fetch / knowledge no system message**: injeta dados do Postgres no contexto pra evitar alucinação de preço/modelo.
- **maxIterations=12 + safety net**: previne o crash "Agent stopped due to max iterations".

---

## 5. Plano de controle (synapseos-agentic) — ADR-001

### ADR-001: Templates read-only + `post_deploy.py`

**Problema:** o deploy do painel (`POST /api/clients/audi/deploy`) renderiza os workflows a partir do **template base Natália** e sobrescreve TODA customização Audi (texto carro vs moto, canais Slack, knowledge Postgres, log no Chatwoot).

**Decisão adotada:**
1. `lock_deploy: true` no `clients/audi.yaml` → bloqueia deploy do painel (423 sem `?force=true`).
2. Fonte da verdade fragmentada por categoria (ver §2).
3. `scripts/audi/post_deploy.py` (~9000 linhas, 43 funções `patch_*`/`ensure_*`, idempotente) re-aplica TODA a customização após qualquer deploy.

**Consequências:**
- ✅ Estabilidade do piloto; mudança rápida via hot redeploy (~30s).
- ❌ **Drift acumula** — n8n UI pode divergir do `reference/audi/`; precisa snapshot+commit periódico.
- ❌ `post_deploy.py` virou um monólito de 9000 linhas — alto custo cognitivo, é a peça mais frágil do sistema.
- ❌ Mudanças via hot redeploy são **efêmeras** (perdem se `synapseos_panel` reinicia); persistir exige build canônico (`vX.Y.Z-agentic`).

---

## 6. Avaliação arquitetural — riscos e trade-offs

### 6.1 Pontos fortes
- **Separação de planos limpa** no nível conceitual: Chatwoot = sistema de registro; n8n = lógica conversacional; painel = provisioning.
- **Auditoria forte:** `CrmEvent` append-only + `SynapseosAgenticDeploymentLog` dão rastreabilidade real.
- **Idempotência** do `post_deploy.py` e dos sub-workflows reduz risco de re-execução.
- **Tratamento robusto de telefone BR** depois de muito sangue (3 variantes em search, canonical com-9).

### 6.2 Riscos / dívida técnica (priorizados)

| # | Risco | Severidade | Evidência |
|---|---|---|---|
| R1 | **`post_deploy.py` monolítico (~9000 linhas)** — fonte de verdade crítica, sem modularização, fácil de quebrar | 🔴 Alta | 43 funções, todas no mesmo arquivo |
| R2 | **Drift n8n UI ↔ `reference/audi/`** — não há reconciliação automática; snapshot é manual | 🔴 Alta | ADR-001 reconhece explicitamente |
| R3 | **Mudanças efêmeras via hot redeploy** — perdem em restart do painel se não viram build | 🟠 Média | memória `audi-session-kickoff` §3 |
| R4 | **account_id/inbox_id=2 hardcoded** — bloqueia 2º tenant sem refactor | 🟠 Média | constantes no `post_deploy.py` |
| R5 | **Dependências externas frágeis**: OpenAI key 401 (fallback estático), Google Sheets sem credencial (WF09 desligado) | 🟠 Média | `audi-pending-work` P2 |
| R6 | **Contact_inboxes duplicados** (3 leads teste com/sem 9) — fix de normalização parou novos, mas legado não foi merjado | 🟡 Baixa | `audi-pending-work` P2 |
| R7 | **Determinismo da LLM** — handoff/equivalência de modelo dependem de prompt steering; smoke tests ainda flutuam | 🟠 Média | smoke 4/18 falhas, equivalente_x6 instável |
| R8 | **Single VPS, sem HA** — Docker Swarm de 1 nó; ponto único de falha pra Chatwoot + n8n + painel + Postgres | 🟠 Média | `158.69.63.140` |

### 6.3 Trade-offs centrais já feitos (e se ainda fazem sentido)

| Trade-off | Escolha atual | Avaliação |
|---|---|---|
| Lógica conversacional: código vs n8n | **n8n** (visual, iterável sem deploy) | ✅ Certo pra fase de piloto/iteração rápida; revisar se virar produto |
| Customização: template-driven vs patch script | **patch script** (ADR-001) | ⚠️ Resolveu o sintoma, criou dívida (R1); ok no curto prazo |
| Inbound Audi: Avisa direto vs via n8n | **Avisa direto** no Chatwoot | ✅ Menos saltos, menos latência; n8n não precisa ver inbound cru |
| Identidade telefone: com 9 vs sem 9 | **canonical com 9** | ✅ Decisão correta; só falta merge do legado |
| Determinismo: tools vs regras de prompt | **regras + handlers post-hoc** | ✅ Pragmático dado o comportamento da LLM |

---

## 7. Recomendações (próximos passos arquiteturais)

**Curto prazo (estabilizar o piloto)**
1. **Concluir deploy do Chatwoot** com commit `6c575171c8` (normalização telefone inbound) — item P1 aberto há semanas.
2. **Canonizar fixes via build** (`build-and-deploy.sh vX.Y.Z-agentic`) — tirar o sistema do regime de hot redeploy efêmero (R3).
3. **Snapshot + commit do estado n8n** em `reference/audi/` pra fechar o gap de drift (R2).

**Médio prazo (reduzir dívida)**
4. **Quebrar `post_deploy.py`** em módulos por workflow (`patches/wf02.py`, `patches/wf04.py`, …) com um runner fino (R1). Mantém idempotência, reduz risco de edição.
5. **Reconciliação de drift**: script que compara workflow live (export n8n) vs `reference/audi/` e falha o CI se divergir (R2).
6. **Resolver dependências mortas**: religar OpenAI key (follow-up personalizado) e decidir destino do WF09/Sheets (R5).

**Longo prazo (preparar 2º tenant / escala)**
7. **Des-hardcodar account_id/inbox_id** — derivar do `clients/*.yaml` por slug (R4). É o gargalo nº1 pra multi-tenant real.
8. **HA mínimo**: separar Postgres (managed ou réplica) do nó de app; backup automatizado verificado (R8).
9. **Suite E2E estável** como gate de deploy — hoje o smoke flutua com a LLM (R7); fixar com prompts versionados + asserts tolerantes.

---

## 8. Referências cruzadas

- `docs/synapseos/data_layer.md`, `slash_commands.md`, `tags_contract.md`, `ecosystem_handoff.md` (Chatwoot fork)
- `synapseos-agentic/docs/architecture/adr-001-templates-readonly.md`
- `synapseos-agentic/docs/runbooks/audi-production-checklist.md`
- `synapseos-agentic/scripts/audi/post_deploy.py` (fonte da verdade das customizações n8n)
- Memórias: `synapseos-architecture`, `audi-pipeline-auto-flow`, `audi-post-deploy`, `audi-session-kickoff`, `synapseos-n8n-chatwoot-ops`
