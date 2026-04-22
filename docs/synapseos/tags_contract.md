# SynapseOS — Contrato de Tags & Eventos

**Fonte-de-verdade** para integração entre o orquestrador externo (N8N) e a UI do SynapseOS. O Dashboard C-Level (`AgentMetrics` + `LiveAgents`) calcula KPIs a partir destas tags/eventos. Qualquer alteração aqui exige sincronização com os workflows do N8N.

**Versão:** 1.0 (2026-04-21)

---

## 1. Labels de Conversa

Aplicadas via Chatwoot Labels API (`POST /api/v1/accounts/:id/conversations/:id/labels`).

| Label | Emissor | Significado | KPI derivado |
|---|---|---|---|
| `lead_novo_recepcionado` | Alice / Iza | Nova conversa inbound ou outbound recebida pelo bot | Volume de Leads Recepcionados (Alice/Iza) |
| `lead_qualificado` | Alice / Iza | Lead passou triagem, é comprador real | Taxa de Qualificação (Alice/Iza). **Dispara transição de pipeline Novo Lead → Qualificado** |
| `crm_updated` | Otto | Otto extraiu dado do chat e preencheu CRM | Interações de CRM (Otto) |
| `sla_alert` | Otto | Otto enviou nota privada de alerta de SLA pro humano | Alertas SLA (Otto) |
| `rescue_transbordo` | Otto | Assignee voltou de `User` (humano) para `AgentBot` (bot de resgate) por falha | Resgates (Otto) |
| `assistencia_tecnica` | Luís | Luís gerou nota privada com dados técnicos/manuais | Assistências Técnicas (Luís) |
| `resgatado_fernanda` | Fernanda | Fernanda reativou conversa inativa/morta | Leads Reativados + Pipeline Resgatado (Fernanda) |
| `farming_revisao` | Ângela | Ângela enviou convite de revisão (oficina) | Agendamentos (Ângela) |
| `farming_crosssell` | Ângela | Ângela ofertou test-drive junto com revisão | Taxa de Cross-sell (Ângela) |
| `inadimplencia_contato` | Vitor | Vitor iniciou cobrança | Contatos iniciados (Vitor) |
| `inadimplencia_recuperada` | Vitor | Vitor fechou acordo/recebeu pagamento | Acordos Fechados + Valor Recuperado (Vitor) |

---

## 2. Eventos CRM (`Synapseos::CrmEvent`)

Criados via `POST /api/v1/accounts/:id/synapseos/crm_events` ou internamente pelo listener.

| `event_type` | Emissor | Payload mínimo | Efeito |
|---|---|---|---|
| `appointment` | Ângela / vendedor | `{ kind: 'revisao' \| 'test_drive', scheduled_at, vehicle? }` | Move deal Qualificado → Negociação. Conta KPI Agendamentos. |
| `deal_won` | ERP (Syonet/NBS) / vendedor | `{ deal_id, amount_cents, closed_at }` | Move deal → Fechado Ganho. Dispara webhook Ângela. |
| `deal_lost` | Otto / vendedor | `{ deal_id, reason: 'silencio' \| 'manual' \| 'lost_to_competitor' }` | Move deal → Perdido. Dispara webhook Fernanda. |
| `pix_sent` | Vitor | `{ amount_cents, deal_id }` | Conta KPI PIX Enviados. |
| `lead_rescued` | Fernanda | `{ conversation_id, previous_assignee_user_id }` | Registro auxiliar de resgate. |

---

## 3. Webhooks de saída

Quando pipeline stage muda, o backend dispara POST JSON para o N8N.

| Gatilho | Env var | Payload |
|---|---|---|
| Deal → `Fechado Ganho` | `N8N_WEBHOOK_ANGELA_URL` | `{ account_id, conversation_id, contact_id, deal_id, amount_cents, event: 'deal_won' }` |
| Deal → `Perdido` | `N8N_WEBHOOK_FERNANDA_URL` | `{ account_id, conversation_id, contact_id, deal_id, event: 'deal_lost', reason }` |
| Inatividade detectada (Otto) | `N8N_WEBHOOK_OTTO_URL` | `{ account_id, conversation_id, last_activity_at, assignee_user_id, event: 'silence_detected' }` |

Headers: `X-Synapseos-Signature: HMAC_SHA256(payload, SYNAPSEOS_WEBHOOK_SECRET)` — N8N deve validar.

---

## 4. Mapeamento de Agente → `sender_type`

Como os 6 agentes aparecem nas tabelas `messages.sender_type`:

| Agente | `sender_type` | Identificação adicional |
|---|---|---|
| Alice / Iza | `AgentBot` | `agent_bot.name` inicia com "Alice" ou "Iza" |
| Otto | `AgentBot` | `agent_bot.name == 'Otto'` |
| Luís | `AgentBot` | `agent_bot.name == 'Luís'` |
| Fernanda | `AgentBot` | `agent_bot.name == 'Fernanda'` |
| Ângela | `AgentBot` | `agent_bot.name == 'Ângela'` |
| Vitor | `AgentBot` | `agent_bot.name == 'Vitor'` |

Backend usa slug estável (`alice_iza`, `otto`, `luis`, `fernanda`, `angela`, `vitor`) pra casar AgentBot → KPIs. Slug vive em `agent_bot.identifier` (custom attr).

---

## 5. Regras de pipeline (transições automáticas)

| Transição | Disparador |
|---|---|
| Novo Lead → Qualificado | Label `lead_qualificado` adicionada à conversa que tem `Synapseos::Deal` |
| Qualificado → Negociação | `CrmEvent` type=`appointment` criado |
| Qualificado/Negociação → Fechado Ganho | `CrmEvent` type=`deal_won` OU vendedor arrasta card |
| Qualquer → Perdido | `CrmEvent` type=`deal_lost` OU Otto detecta `silencio_operacional` (`last_activity_at < now - SLA_THRESHOLD_MINUTES`) |

---

## 6. Versionamento

Mudança em nome de tag OU na semântica → incrementa versão e **notifica o time do N8N antes de deployar**.

- v1.0 (2026-04-21): versão inicial junto com S2/S5.
