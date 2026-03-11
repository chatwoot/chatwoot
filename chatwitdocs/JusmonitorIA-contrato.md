# Contrato de Integração Chatwit ↔ JusMonitorIA

> **Versão:** 1.0
> **Data:** 2026-03-09
> **Status:** Em implementação

---

## Índice

1. [Visão Geral](#1-visão-geral)
2. [Arquitetura](#2-arquitetura)
3. [Bot Auto-Provisionado](#3-bot-auto-provisionado)
4. [Labels Auto-Provisionadas](#4-labels-auto-provisionadas)
5. [Eventos Encaminhados](#5-eventos-encaminhados)
6. [Payloads por Evento](#6-payloads-por-evento)
7. [Respostas Bidirecionais](#7-respostas-bidirecionais)
8. [Variáveis de Ambiente](#8-variáveis-de-ambiente)
9. [Futuro: Pagamentos](#9-futuro-pagamentos)
10. [Sync Bidirecional de Contatos (identifier)](#10-sync-bidirecional-de-contatos-identifier)
11. [Changelog](#11-changelog)

---

## 1. Visão Geral

O **JusMonitorIA** (jusmonitoria.witdev.com.br) é o sistema de monitoramento jurídico de processos. Ele é o **cérebro jurídico** — processa consultas de andamento processual, monitora publicações do Diário de Justiça, e responde leads com informações atualizadas sobre seus processos.

O **Chatwit** é o **carteiro** — encaminha eventos (contatos, labels, mensagens) para o JusMonitorIA e entrega respostas de volta ao lead via WhatsApp/Instagram/Facebook.

**Regra fundamental:** O Chatwit NUNCA processa lógica jurídica. Toda inteligência está no JusMonitorIA.

### Duas vias de comunicação

| Via | Direção | Descrição |
|-----|---------|-----------|
| **Sync (webhook)** | Chatwit → JusMonitorIA | Chatwit envia evento e mantém ponte aberta por 15s. Resposta volta na mesma request. |
| **Async (Agent Bot API)** | JusMonitorIA → Chatwit | JusMonitorIA envia via bot token para respostas que ultrapassam 15s ou campanhas. |

---

## 2. Arquitetura

```
┌─────────────────────────────────────────────────────┐
│                      Chatwit                        │
│                                                     │
│  HookListener → HookJob → ProcessorService          │
│       ↓                        ↓                    │
│  conversation_updated    WebhookForwarderService     │
│  contact_created         (POST /v1/integrations/    │
│  message_created          chatwit)                  │
│       ↓                        ↓                    │
│  ResponseProcessor ← ── ── sync response            │
│       ↓                                             │
│  WhatsApp/Instagram/Facebook API                    │
└─────────────────────────────────────────────────────┘
            ↕ HTTP
┌─────────────────────────────────────────────────────┐
│                   JusMonitorIA                       │
│                                                     │
│  POST /v1/integrations/chatwit                      │
│  Roteamento por event_type:                         │
│    contact.created  → Criar lead/cliente            │
│    contact.updated  → Atualizar cadastro            │
│    tag.added        → Ativar monitoramento          │
│    tag.removed      → Desativar monitoramento       │
│    message.received → Processar consulta jurídica   │
│    conversation.resolved → Fechar atendimento       │
│    payment.*        → Sistema financeiro (futuro)   │
│                                                     │
│  POST /v1/integrations/chatwit/init                 │
│    Recebe agent_bot_token para respostas async      │
└─────────────────────────────────────────────────────┘
```

### Componentes no Chatwit

```
config/initializers/
└── jusmonitoria_bot.rb              # Auto-provisioning do Agent Bot + labels + init

lib/integrations/jusmonitoria/
├── processor_service.rb             # Roteador de eventos
├── webhook_forwarder_service.rb     # HTTP client fire-and-forget
└── response_processor.rb           # Processador de respostas bidirecionais
```

---

## 3. Bot Auto-Provisionado

No startup do Chatwit, o initializer `jusmonitoria_bot.rb`:

1. Cria (ou encontra) `AgentBot` global com `name: 'JusMonitorIA Bot'`, `account_id: nil`
2. Registra o token no JusMonitorIA via `POST /v1/integrations/chatwit/init`

### Payload de Init

```json
POST {JUSMONITORIA_WEBHOOK_URL}/v1/integrations/chatwit/init

{
  "agent_bot_token": "auto_generated_token",
  "base_url": "https://chatwit.witdev.com.br",
  "secret": "shared_secret"
}
```

### Módulo de Acesso

```ruby
Chatwit::JusmonitoriaBot.token  # => "bot_access_token"
Chatwit::JusmonitoriaBot.bot    # => AgentBot instance
```

---

## 4. Labels Auto-Provisionadas

No startup, para cada `Account` existente, o initializer cria a label:

- **`jusmonitoria_monitoramento`** — Ativa monitoramento de processos para a conversa

### Convenção de prefixo

Todas as labels do JusMonitorIA usam o prefixo `jusmonitoria_`. Isso permite:
- Isolamento: SocialWise ignora labels com esse prefixo
- Identificação fácil no painel do Chatwit
- Filtros e buscas por integração

### Labels planejadas

| Label | Função |
|-------|--------|
| `jusmonitoria_monitoramento` | Ativa monitoramento de processos |
| `jusmonitoria_pagamento` | (Futuro) Controle financeiro |

---

## 5. Eventos Encaminhados

| Evento Chatwit | event_type no JusMonitorIA | Condição |
|----------------|---------------------------|----------|
| `contact.created` | `contact.created` | Sempre |
| `contact.updated` | `contact.updated` | Sempre |
| `conversation.updated` (label added) | `tag.added` | Label com prefixo `jusmonitoria_` adicionada |
| `conversation.updated` (label removed) | `tag.removed` | Label com prefixo `jusmonitoria_` removida |
| `message.created` | `message.received` | Conversa tem label `jusmonitoria_*` |
| `conversation.resolved` | `conversation.resolved` | Conversa tem label `jusmonitoria_*` |

---

## 6. Payloads por Evento

### 6.1 contact.created / contact.updated

```json
POST {JUSMONITORIA_WEBHOOK_URL}/v1/integrations/chatwit

{
  "event_type": "contact.created",
  "data": {
    "id": 123,
    "name": "João Silva",
    "email": "joao@example.com",
    "phone_number": "+5511999999999",
    "identifier": "whatsapp_id",
    "custom_attributes": {},
    "account": { "id": 1, "name": "Escritório ABC" }
  },
  "metadata": {
    "account_id": 1,
    "chatwit_base_url": "https://chatwit.witdev.com.br",
    "chatwit_agent_bot_token": "bot_token",
    "timestamp": "2026-03-09T12:00:00Z"
  }
}
```

### 6.2 tag.added / tag.removed

```json
{
  "event_type": "tag.added",
  "data": {
    "tag": "jusmonitoria_monitoramento",
    "conversation": {
      "id": 456,
      "status": "open",
      "contact": { "id": 123, "name": "João Silva" },
      "inbox": { "id": 1, "name": "WhatsApp" }
    }
  },
  "metadata": { ... }
}
```

### 6.3 message.received

```json
{
  "event_type": "message.received",
  "data": {
    "message": {
      "id": 789,
      "content": "Dr, como está meu processo?",
      "message_type": "incoming",
      "content_type": "text",
      "content_attributes": {},
      "conversation_id": 456
    },
    "contact": { "id": 123, "name": "João Silva" },
    "conversation": { "id": 456, "labels": ["jusmonitoria_monitoramento"] },
    "inbox": { "id": 1, "channel_type": "Channel::Whatsapp" }
  },
  "metadata": { ... }
}
```

### 6.4 conversation.resolved

```json
{
  "event_type": "conversation.resolved",
  "data": {
    "conversation": {
      "id": 456,
      "status": "resolved",
      "contact": { "id": 123, "name": "João Silva" },
      "labels": ["jusmonitoria_monitoramento"]
    }
  },
  "metadata": { ... }
}
```

---

## 7. Respostas Bidirecionais

O JusMonitorIA pode responder sincronamente ao webhook de `message.received`. O `ResponseProcessor` do Chatwit processa a resposta e envia ao lead.

### Formato de Resposta Sync

```json
{
  "responses": [
    {
      "type": "text",
      "content": "Seu processo 0001234-56.2024.8.26.0100 teve movimentação em 08/03/2026: Juntada de petição."
    }
  ],
  "actions": ["handoff", "resolve"]
}
```

### Tipos de Resposta Suportados

| Tipo | Descrição |
|------|-----------|
| `text` | Mensagem de texto simples |
| `interactive` | Mensagem interativa WhatsApp (botões, listas) |
| `template` | Template WhatsApp pré-aprovado |

### Ações Suportadas

| Ação | Descrição |
|------|-----------|
| `handoff` | Transfere conversa para atendente humano |
| `resolve` | Resolve/fecha a conversa |

### Resposta Async

Se o JusMonitorIA precisar de mais tempo (pesquisa de processos pode demorar), responde:

```json
{
  "async": true
}
```

E depois envia a resposta via Agent Bot API usando o `agent_bot_token` registrado no init.

---

## 8. Variáveis de Ambiente

| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `JUSMONITORIA_WEBHOOK_URL` | URL base do JusMonitorIA | `https://jusmonitoria.witdev.com.br` |
| `CHATWIT_WEBHOOK_SECRET` | Secret compartilhado (reutiliza com SocialWise) | — |
| `FRONTEND_URL` | Base URL do Chatwit | `https://chatwit.witdev.com.br` |

---

## 9. Pagamentos (InfinitePay)

A integração de pagamentos via InfinitePay está implementada. O fluxo:

1. Agente envia link de pagamento via modal na conversa
2. InfinitePay envia webhook `POST /webhooks/infinitepay` ao Chatwit quando o pagamento é confirmado
3. Chatwit encaminha para **ambos** SocialWise e JusMonitorIA como `payment.confirmed`
4. JusMonitorIA usa para controle financeiro (match de fatura, baixa automática)
5. SocialWise usa para fluxos de pós-venda

### Payload `payment.confirmed`

```json
{
  "event_type": "payment.confirmed",
  "data": {
    "payment_link_id": 123,
    "order_nsu": "chatwit-1-456-abc123",
    "amount_cents": 1000,
    "paid_amount_cents": 1010,
    "capture_method": "pix",
    "receipt_url": "https://comprovante.com/123",
    "conversation_id": 456,
    "contact": {
      "id": 789,
      "name": "João Silva",
      "phone_number": "+5511999887766"
    }
  },
  "metadata": {
    "account_id": 1,
    "chatwit_base_url": "https://chatwit.witdev.com.br",
    "chatwit_agent_bot_token": "bot-token",
    "timestamp": "2026-03-10T12:00:00Z"
  }
}
```

### Campos do `data`

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `payment_link_id` | integer | ID do PaymentLink no Chatwit |
| `order_nsu` | string | NSU gerado pelo Chatwit (`chatwit-{account_id}-{conversation_id}-{hex}`) |
| `amount_cents` | integer | Valor original em centavos |
| `paid_amount_cents` | integer | Valor efetivamente pago em centavos |
| `capture_method` | string | `"pix"` ou `"credit_card"` |
| `receipt_url` | string | URL do comprovante |
| `conversation_id` | integer | ID da conversa no Chatwit |
| `contact` | object | Dados do contato (id, name, phone_number) |

---

## 10. Sync Bidirecional de Contatos (identifier)

> **Status:** ✅ IMPLEMENTADO (2026-03-11)
> **Referência Roadmap:** Seção 3.6 (Kanban de Leads) + Seção 1.6 (Tenant Resolution)
> **Complexidade:** Média
> **Quem implementa:** Equipe JusMonitorIA (100% backend JusMonitorIA — Chatwit já suporta)

### 10.1 Contexto

Hoje o link entre Contact (Chatwit) e Lead/Client (JusMonitorIA) é **unidirecional**:
- O JusMonitorIA salva `chatwit_contact_id` no Lead/Client → sabe qual contact é no Chatwit ✅
- O Chatwit **não sabe** de qual Lead/Client se trata no JusMonitorIA ❌

Isso impede que o Chatwit exiba informações do CRM (ex: score do lead, stage do funil) e dificulta quick actions no Kanban.

### 10.2 Solução: Campo `identifier` no Chatwit

O Chatwit possui um campo `identifier` na tabela `contacts` que é:
- **Único por account** (unique index: `account_id + identifier`)
- **Editável via Agent Bot API** (endpoint `PATCH /api/v1/accounts/{account_id}/contacts/{contact_id}` já acessível pelo bot)
- **Pesquisável** via `GET /api/v1/accounts/{account_id}/contacts/search?q={identifier}`

### 10.3 Arquitetura do Link Bidirecional

```
┌─────────────────────────┐          ┌─────────────────────────┐
│  JusMonitorIA (Lead)    │          │  Chatwit (Contact)      │
│                         │          │                         │
│  chatwit_contact_id ────┼────────► │  id: 123                │
│    = "123"              │          │                         │
│                         │ ◄────────┼── identifier            │
│  id: uuid-abc-123       │          │    = "jm_uuid-abc-123"  │
└─────────────────────────┘          └─────────────────────────┘
```

### 10.4 Convenção do Identifier

| Tipo | Formato | Exemplo |
|------|---------|---------|
| Lead | `jm_lead_{lead.id}` | `jm_lead_a1b2c3d4-e5f6-...` |
| Client | `jm_client_{client.id}` | `jm_client_x9y8z7w6-...` |

O prefixo `jm_` (JusMonitorIA) garante que não colide com identifiers de outras integrações.

### 10.5 O que o JusMonitorIA precisa implementar

#### A) Handler para `contact.created` (NOVO)

O schema `ChatwitContactEventPayload` já existe em `backend/app/schemas/chatwit.py` mas **não está wired a nenhum handler**.

Implementar em `backend/app/workers/tasks/chatwit_handlers.py`:

```python
async def handle_contact_created(payload: dict, tenant_id: UUID, db: AsyncSession):
    """
    Recebe contact.created do Chatwit.
    1. Cria Lead no CRM com source=CHATWIT
    2. Seta identifier no Chatwit via Agent Bot API (link bidirecional)
    """
    contact_data = payload["data"]
    chatwit_contact_id = str(contact_data["id"])
    
    # Verificar se já existe
    existing = await lead_repo.get_by_chatwit_contact(chatwit_contact_id)
    if existing:
        return  # já vinculado
    
    # Criar Lead
    lead = await lead_repo.create(
        tenant_id=tenant_id,
        name=contact_data.get("name", ""),
        email=contact_data.get("email"),
        phone=contact_data.get("phone_number"),
        source=LeadSource.CHATWIT,
        chatwit_contact_id=chatwit_contact_id,
    )
    
    # Setar identifier no Chatwit (link bidirecional)
    await sync_identifier_to_chatwit(
        lead=lead,
        chatwit_contact_id=chatwit_contact_id,
        metadata=payload["metadata"],
    )
```

#### B) Função `sync_identifier_to_chatwit` (NOVA)

Utility para setar o `identifier` no Chatwit via Agent Bot API:

```python
async def sync_identifier_to_chatwit(
    lead,
    chatwit_contact_id: str,
    metadata: dict,
    entity_type: str = "lead",  # "lead" ou "client"
):
    """
    PATCH no Chatwit para setar identifier = jm_{type}_{id}
    
    Usa o Agent Bot token (metadata.chatwit_agent_bot_token)
    Endpoint: PATCH /api/v1/accounts/{account_id}/contacts/{contact_id}
    """
    base_url = metadata["chatwit_base_url"]
    account_id = metadata["account_id"]
    bot_token = metadata["chatwit_agent_bot_token"]
    
    identifier = f"jm_{entity_type}_{lead.id}"
    
    url = f"{base_url}/api/v1/accounts/{account_id}/contacts/{chatwit_contact_id}"
    headers = {"api_access_token": bot_token}
    payload = {"identifier": identifier}
    
    async with httpx.AsyncClient(timeout=10) as client:
        response = await client.patch(url, json=payload, headers=headers)
        response.raise_for_status()
    
    return identifier
```

#### C) Atualizar `handle_message_received` (EXISTENTE)

O handler existente em `chatwit_handlers.py` já cria Leads ao receber mensagens. Adicionar chamada ao `sync_identifier_to_chatwit` após criar o Lead:

```python
# Após criar o lead (linha ~120 do handler existente):
await sync_identifier_to_chatwit(
    lead=lead,
    chatwit_contact_id=chatwit_contact_id,
    metadata=payload["metadata"],
)
```

#### D) Na conversão Lead → Client

Quando um Lead é convertido em Client, atualizar o identifier:

```python
async def on_lead_converted_to_client(lead, client, metadata):
    """Atualiza identifier de jm_lead_X para jm_client_Y"""
    await sync_identifier_to_chatwit(
        lead=client,  # client também tem chatwit_contact_id
        chatwit_contact_id=client.chatwit_contact_id,
        metadata=metadata,
        entity_type="client",
    )
```

#### E) Wiring do evento no webhook router

No arquivo que roteia os eventos (`webhooks.py` ou `chatwit_handlers.py`), adicionar:

```python
event_handlers = {
    "contact.created": handle_contact_created,    # ← NOVO
    "contact.updated": handle_contact_updated,     # ← NOVO (atualizar nome/email/phone)
    "message.received": handle_message_received,   # existente
    "tag.added": handle_tag_added,                 # existente
    "tag.removed": handle_tag_removed,             # existente
    "conversation.resolved": handle_conversation_resolved,
    "payment.confirmed": handle_payment_confirmed,
}
```

### 10.6 O que o Chatwit já suporta (nada a fazer)

| Funcionalidade | Status | Detalhe |
|----------------|--------|---------|
| Campo `identifier` em `contacts` | ✅ Existe | Unique por account, indexado |
| PATCH contact via Agent Bot | ✅ Funciona | `contacts` está em `BOT_ACCESSIBLE_ENDPOINTS` |
| Envio de `contact.created` no webhook | ✅ Funciona | Já encaminhado pelo `ProcessorService` |
| Busca por identifier | ✅ Funciona | `GET /contacts/search?q=jm_lead_...` |

### 10.7 Payload de Referência — PATCH Contact

```http
PATCH /api/v1/accounts/{account_id}/contacts/{contact_id}
Content-Type: application/json
api_access_token: {agent_bot_token}

{
  "identifier": "jm_lead_a1b2c3d4-e5f6-7890-abcd-ef1234567890"
}
```

**Response (200 OK):**
```json
{
  "id": 123,
  "name": "João Silva",
  "email": "joao@example.com",
  "phone_number": "+5511999887766",
  "identifier": "jm_lead_a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "custom_attributes": {}
}
```

### 10.8 Fluxo Completo

```
1. Pessoa envia WhatsApp → Chatwit recebe
2. Chatwit cria Contact (se novo) → dispara contact.created
3. Chatwit encaminha contact.created → JusMonitorIA webhook
4. JusMonitorIA cria Lead com chatwit_contact_id = contact.id
5. JusMonitorIA faz PATCH no Chatwit: identifier = "jm_lead_{uuid}"
6. ✅ Link bidirecional completo

--- Meses depois, lead vira cliente ---

7. Advogado converte Lead → Client no CRM
8. JusMonitorIA faz PATCH no Chatwit: identifier = "jm_client_{uuid}"
9. ✅ Chatwit agora sabe que é um Cliente do JusMonitorIA
```

### 10.9 Migração de Contacts Existentes

Para os 2.341 contacts que já existem no Chatwit e podem ter Leads no JusMonitorIA:

```python
async def migrate_existing_identifiers(db: AsyncSession, metadata: dict):
    """
    Script de migração one-time.
    Para cada Lead/Client que tem chatwit_contact_id,
    faz PATCH no Chatwit para setar o identifier.
    """
    # Leads
    leads = await lead_repo.get_all_with_chatwit_contact(db)
    for lead in leads:
        try:
            await sync_identifier_to_chatwit(
                lead=lead,
                chatwit_contact_id=lead.chatwit_contact_id,
                metadata=metadata,
                entity_type="lead",
            )
        except Exception as e:
            logger.warning(f"Failed to sync identifier for lead {lead.id}: {e}")
    
    # Clients
    clients = await client_repo.get_all_with_chatwit_contact(db)
    for client in clients:
        try:
            await sync_identifier_to_chatwit(
                lead=client,
                chatwit_contact_id=client.chatwit_contact_id,
                metadata=metadata,
                entity_type="client",
            )
        except Exception as e:
            logger.warning(f"Failed to sync identifier for client {client.id}: {e}")
```

Executar como management command ou one-time task após deploy.

---

## 11. Changelog

| Data | Seção | Status | Descrição |
|------|-------|--------|-----------|
| 2026-03-09 | 1-8 | IMPLEMENTADO | Integração inicial: bot, labels, eventos, respostas bidirecionais |
| 2026-03-10 | 9 | IMPLEMENTADO | Integração de pagamentos InfinitePay com payload `payment.confirmed` |
| 2026-03-11 | 10 | IMPLEMENTADO | Sync bidirecional de contatos via `identifier` — implementação 100% no JusMonitorIA |
