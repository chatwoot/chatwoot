# Contrato Chatwit: Respostas Assíncronas Além de 30 Segundos

> **Versão**: 1.8.0
> **Data**: 12 de Fevereiro de 2026
> **Escopo**: Tudo que precisa mudar no Chatwit (fork Chatwoot v4.10) + integrações Socialwise
> **Referência**: `docs/interative_message_flow_builder.md` §14 e §17

---

## 🚀 STATUS: CHATWIT PRONTO - AGUARDANDO SOCIALWISE

### O que foi implementado no Chatwit (✅ Concluído)

| Funcionalidade | Status | Descrição |
|----------------|--------|-----------|
| Timeout configurável | ✅ | `SOCIALWISE_FLOW_TIMEOUT` ENV (default: 30s) |
| Aceitar resposta async | ✅ | `{"status":"accepted","async":true}` não gera erro |
| Dispatcher interactive | ✅ | Mensagens via API com botões funcionam no WhatsApp |
| Payload com metadata | ✅ | `chatwit_base_url`, `account_id`, `conversation_id` no webhook |
| Agent Bot API | ✅ | API nativa pronta para receber mensagens async |
| Bot global auto-provisionado | ✅ | Socialwise Bot criado automaticamente no startup, token enviado no webhook |
| Bot global acessa qualquer conta | ✅ | Bots com `account_id=NULL` podem acessar todas as contas sem AgentBotInbox |

### O que o SocialWise precisa fazer

| Tarefa | Prioridade | Descrição |
|--------|------------|-----------|
| ~~1. Criar Agent Bot~~ | ✅ Automático | Bot global auto-provisionado no startup do Chatwit |
| ~~2. Configurar token~~ | ✅ Automático | Token enviado no `metadata.chatwit_agent_bot_token` do webhook |
| 3. Conectar FlowOrchestrator | 🟡 Média | Integrar ao webhook para usar Dual-Mode |
| 4. Implementar entrega async | 🟡 Média | Usar API Agent Bot quando `canSync()=false` — ler token de `metadata.chatwit_agent_bot_token` |

### Payload que o Chatwit envia ao SocialWise

```json
{
  "session_id": "558597550136",
  "message": "Olá!",
  "channel_type": "Channel::Whatsapp",
  "language": "pt-BR",
  "metadata": {
    "account_id": 1,
    "conversation_id": 123,
    "message_id": 456,
    "inbox_id": 2,
    "chatwit_base_url": "https://seu-chatwit.exemplo.com",
    "chatwit_agent_bot_token": "auto_generated_token_here"
  },
  "context": { ... },
  "button_id": "@falar_atendente",
  "interaction_type": "button_reply"
}
```

### API para o SocialWise enviar mensagens async

```http
POST {chatwit_base_url}/api/v1/accounts/{account_id}/conversations/{conversation_id}/messages
Headers:
  api_access_token: {metadata.chatwit_agent_bot_token}
  Content-Type: application/json

# Mensagem de texto
Body: {"content": "Olá!", "message_type": "outgoing"}

# Mensagem interativa com botões
Body: {
  "content": "Escolha uma opção:",
  "message_type": "outgoing",
  "content_type": "integrations",
  "content_attributes": {
    "interactive": {
      "type": "button",
      "body": {"text": "Escolha uma opção:"},
      "action": {
        "buttons": [
          {"type": "reply", "reply": {"id": "btn_1", "title": "Opção 1"}},
          {"type": "reply", "reply": {"id": "btn_2", "title": "Opção 2"}}
        ]
      }
    }
  }
}
```

### API para o SocialWise enviar mídia (imagens, PDFs, vídeos) via URL pública

O Chatwit **NÃO aceita URL direta** no endpoint de mensagens. É necessário um **fluxo de 2 etapas**:

#### Fluxo de 2 Etapas para Mídia

```
Etapa 1: Upload da URL → Chatwit baixa o arquivo e retorna um blob_id (signed_id)
Etapa 2: Criar mensagem → Usar o blob_id como attachment
```

#### Etapa 1: Upload via URL pública

```http
POST {chatwit_base_url}/api/v1/accounts/{account_id}/upload
Headers:
  api_access_token: {metadata.chatwit_agent_bot_token}
  Content-Type: application/json
Body:
  {
    "external_url": "https://exemplo.com/documento.pdf"
  }
```

**Resposta (200 OK):**
```json
{
  "file_url": "https://chatwit.witdev.com.br/rails/active_storage/blobs/redirect/abc123/documento.pdf",
  "blob_id": "eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBZ1VQ..."
}
```

#### Etapa 2: Criar mensagem com o blob_id como attachment

```http
POST {chatwit_base_url}/api/v1/accounts/{account_id}/conversations/{conversation_display_id}/messages
Headers:
  api_access_token: {metadata.chatwit_agent_bot_token}
  Content-Type: application/json
Body:
  {
    "content": "Segue o documento solicitado.",
    "message_type": "outgoing",
    "attachments": ["eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBZ1VQ..."]
  }
```

> **IMPORTANTE:** O campo `attachments` é um **array de strings** (signed_ids), não um array de objetos.
> **IMPORTANTE:** Use `conversation_display_id` (ex: 2514) na URL, **NÃO** o `conversation_id` interno (ex: 2724).

#### Exemplos cURL completos

**Imagem via URL:**
```bash
# Etapa 1: Upload
BLOB_ID=$(curl -s -X POST "https://chatwit.witdev.com.br/api/v1/accounts/3/upload" \
  -H "api_access_token: 5rxTkF7gs9H9E9jqEW4fqeas" \
  -H "Content-Type: application/json" \
  -d '{"external_url": "https://exemplo.com/foto.jpg"}' \
  | jq -r '.blob_id')

# Etapa 2: Enviar mensagem com a imagem
curl -X POST "https://chatwit.witdev.com.br/api/v1/accounts/3/conversations/2514/messages" \
  -H "api_access_token: 5rxTkF7gs9H9E9jqEW4fqeas" \
  -H "Content-Type: application/json" \
  -d "{\"content\": \"Aqui está a imagem!\", \"message_type\": \"outgoing\", \"attachments\": [\"$BLOB_ID\"]}"
```

**PDF via URL:**
```bash
# Etapa 1: Upload
BLOB_ID=$(curl -s -X POST "https://chatwit.witdev.com.br/api/v1/accounts/3/upload" \
  -H "api_access_token: 5rxTkF7gs9H9E9jqEW4fqeas" \
  -H "Content-Type: application/json" \
  -d '{"external_url": "https://exemplo.com/contrato.pdf"}' \
  | jq -r '.blob_id')

# Etapa 2: Enviar mensagem com o PDF
curl -X POST "https://chatwit.witdev.com.br/api/v1/accounts/3/conversations/2514/messages" \
  -H "api_access_token: 5rxTkF7gs9H9E9jqEW4fqeas" \
  -H "Content-Type: application/json" \
  -d "{\"content\": \"Segue o contrato em PDF.\", \"message_type\": \"outgoing\", \"attachments\": [\"$BLOB_ID\"]}"
```

#### Implementação TypeScript sugerida para o SocialWise

```typescript
// services/flow-engine/chatwit-delivery-service.ts

async function deliverMedia(
  baseUrl: string,
  accountId: number,
  conversationDisplayId: number,
  token: string,
  mediaUrl: string,
  caption: string
): Promise<void> {
  // Etapa 1: Upload via URL
  const uploadRes = await axios.post(
    `${baseUrl}/api/v1/accounts/${accountId}/upload`,
    { external_url: mediaUrl },
    { headers: { api_access_token: token, 'Content-Type': 'application/json' } }
  );
  const blobId = uploadRes.data.blob_id;

  // Etapa 2: Criar mensagem com attachment
  await axios.post(
    `${baseUrl}/api/v1/accounts/${accountId}/conversations/${conversationDisplayId}/messages`,
    {
      content: caption,
      message_type: 'outgoing',
      attachments: [blobId]
    },
    { headers: { api_access_token: token, 'Content-Type': 'application/json' } }
  );
}
```

#### Tipos de mídia suportados

| Tipo | Content-Type detectado | file_type no Chatwit |
|------|----------------------|---------------------|
| JPEG/PNG/GIF/WebP | `image/*` | `image` |
| PDF | `application/pdf` | `file` |
| MP4/WebM | `video/*` | `video` |
| MP3/OGG/WAV | `audio/*` | `audio` |
| Outros | `application/*` | `file` |

> O Chatwit detecta o `file_type` automaticamente a partir do `Content-Type` da URL.
> O WhatsApp Cloud API aceita: imagens (JPEG, PNG), documentos (PDF), áudio (OGG Opus, MP3), vídeo (MP4).

#### Erros comuns

| Erro | Causa | Solução |
|------|-------|---------|
| **422** na etapa 1 | URL inválida ou inacessível | Verificar se a URL é HTTPS e acessível publicamente |
| **422** na etapa 2 | `blob_id` inválido ou expirado | Usar o `blob_id` logo após o upload (não cachear por muito tempo) |
| **404** na etapa 2 | Usando `conversation_id` em vez de `display_id` | Usar `metadata.conversation_display_id` do webhook |
| **401** | Token inválido | Usar `metadata.chatwit_agent_bot_token` do webhook |

### Fluxo Dual-Mode resumido

```
                    Chatwit                              SocialWise
                       │                                     │
   Msg WhatsApp ──────▶│ POST webhook ─────────────────────▶│
                       │                                     │
                       │                              ┌──────┴──────┐
                       │                              │ canSync()?  │
                       │                              └──────┬──────┘
                       │                                     │
                       │◀─── SYNC: {"text":"..."} ──────────┤ (< 28s)
                       │                                     │
                       │◀─── ASYNC: {"status":"accepted"} ──┤ (> 28s)
                       │                                     │
                       │     ┌───────────────────────────────┤
                       │     │                               │
                       │◀────┤ POST /api/.../messages ───────┤ (após delay)
                       │     │                               │
                       ▼     ▼                               ▼
```

---

## Índice

1. [Situação Atual — O Gargalo dos 30s](#1-situação-atual--o-gargalo-dos-30s)
2. [Arquitetura Alvo — Dual-Mode (Sync + Async)](#2-arquitetura-alvo--dual-mode-sync--async)
3. [Requisito 1: Agent Bot — Zero Código (Config)](#3-requisito-1-agent-bot--zero-código-config)
4. [Requisito 2: Dispatcher Interactive (Código Ruby)](#4-requisito-2-dispatcher-interactive-código-ruby)
5. [Requisito 3: `button_reply.id` no Webhook (Verificação)](#5-requisito-3-button_replyid-no-webhook-verificação)
6. [Requisito 4: ProcessorService — Aceitar Resposta Async](#6-requisito-4-processorservice--aceitar-resposta-async)
7. [Requisito 5: Wiring no Socialwise (FlowOrchestrator)](#7-requisito-5-wiring-no-socialwise-floworchestrator)
8. [Contrato JSON — Formatos de Resposta](#8-contrato-json--formatos-de-resposta)
9. [Tabela Resumo de Mudanças](#9-tabela-resumo-de-mudanças)
10. [Checklist de Validação](#10-checklist-de-validação)
11. [Troubleshooting](#11-troubleshooting)
12. [Campanhas em Massa](#12-campanhas-em-massa-flow-campaigns--informativo-para-o-chatwit)
13. [Dispatch de Templates via Agent Bot](#13-dispatch-de-templates-whatsapp-via-api-agent-bot-necessário)
14. [Adicionar contacts ao BOT_ACCESSIBLE_ENDPOINTS](#14-adicionar-contacts-ao-bot_accessible_endpoints-necessário)
15. [Init do Agent Bot — Registrar token no Socialwise](#15-init-do-agent-bot--registrar-token-no-socialwise-necessário)

---

## 1. Situação Atual — O Gargalo dos 30s

### Como funciona hoje

```
Meta (WhatsApp) ──webhook──▶ Chatwit
                                │
                         ┌──────▼──────────────────────────────────┐
                         │ SocialwiseFlow::ProcessorService         │
                         │                                          │
                         │  process_content(message)                │
                         │    └─ get_response(session_id, content)  │
                         │         │                                │
                         │    HTTParty.post(                        │
                         │      url_socialwise,                     │
                         │      body: payload.to_json,              │
                         │      timeout: 30  ◄── GARGALO            │
                         │    )                                     │
                         │         │                                │
                         │    Espera resposta síncrona...           │
                         │         │                                │
                         │    process_response(message, response)   │
                         │    └─ create_conversation(...)           │
                         │    └─ SendReplyJob → WhatsApp API        │
                         └──────────────────────────────────────────┘
```

### Código Ruby responsável

**Arquivo**: `lib/integrations/socialwise_flow/processor_service.rb` — linha 334:

```ruby
response = HTTParty.post(url, headers: headers, body: payload.to_json, timeout: 30)
```

### Limitações

| Limitação | Impacto |
|-----------|---------|
| **Timeout fixo de 30s** | Flows com delay, IA lenta, HTTP externo, ou múltiplas etapas estouram o timeout |
| **Uma única resposta** | Não é possível enviar texto + delay + PDF + botão no mesmo flow |
| **Síncrono bloqueante** | O job do Sidekiq fica preso esperando a resposta — desperdiça recursos |
| **Sem retry para async** | Se o Socialwise precisa de mais tempo, não há como "continuar depois" |

### Arquivos envolvidos (Chatwit)

| Arquivo | Papel |
|---------|-------|
| `lib/integrations/socialwise_flow/processor_service.rb` | O gargalo — `get_response()` com timeout 30s |
| `app/services/whatsapp/providers/whatsapp_cloud_service.rb` | Envia mensagens pra WhatsApp (send_message + send_interactive_payload) |
| `app/builders/messages/message_builder.rb` | Cria `Message` — já aceita `content_type` e `content_attributes` |
| `app/models/message.rb` | Modelo — já tem enum `integrations: 10` no `content_type` |
| `app/models/message.rb` | `send_reply` — respeita `skip_send_reply` em `additional_attributes` |
| `app/controllers/concerns/access_token_auth_helper.rb` | Auth por `api_access_token` — já autoriza Agent Bot |

---

## 2. Arquitetura Alvo — Dual-Mode (Sync + Async)

### Visão geral

```
Meta ──webhook──▶ Chatwit ──POST──▶ Socialwise
                                        │
                                  ┌─────┴─────┐
                                  │ CRONÔMETRO │ ← Inicia: 28s
                                  │ (deadline) │
                                  └─────┬─────┘
                                        │
                              ┌─────────▼─────────────┐
                              │ FlowOrchestrator       │
                              │                        │
                              │  Classifica intent     │
                              │  Carrega flow          │
                              │  Executa nó a nó       │
                              └─────────┬─────────────┘
                                        │
                            ┌───────────▼───────────────┐
                            │  A cada nó de ENVIO:       │
                            │                            │
                            │  Restante > 5s?            │
                            │     SIM → acumula sync     │
                            │     NÃO → envia via API    │
                            │           Chatwit (async)  │
                            └───────────┬───────────────┘
                                        │
                              ┌─────────▼─────────────┐
                              │ RESPOSTA HTTP          │
                              │                        │
                              │ MODO A (sync):         │
                              │ { "fulfillmentMessages" │
                              │   : [...mensagens...] } │
                              │                        │
                              │ MODO B (async):        │
                              │ { "status":"accepted", │
                              │   "async":true }       │
                              │ + mensagens vão via    │
                              │   API REST Agent Bot   │
                              └────────────────────────┘
```

### O princípio: Deadline-First

O `DeadlineGuard` (já implementado no Socialwise em `services/flow-engine/deadline-guard.ts`) decide **em tempo real** se cada mensagem pode ser entregue via ponte síncrona ou deve ir via API:

```
DeadlineGuard(deadlineMs=28000, safetyMarginMs=5000)

canSync() → true se restante > safetyMarginMs E ponte não fechou
```

Uma vez que muda para async, **nunca volta** para sync (Ponto Sem Retorno).

### Fluxo detalhado — Passo a passo

```
1. Chatwit recebe mensagem do WhatsApp
2. SocialwiseFlow::ProcessorService.get_response() → POST ao Socialwise
3. Socialwise inicia cronômetro (28s)
4. Classifica intent via IA (pode levar 2-15s)
5. Carrega flow associado
6. Executa nó 1 (texto): canSync()=true → acumula na resposta sync
7. Executa nó 2 (botão): canSync()=true → acumula na resposta sync
8. Executa nó 3 (delay 10s): FORÇA async → marca ponto-sem-retorno
9. Responde HTTP com nós 1+2 no body (sync)
   └─ OU responde {"status":"accepted","async":true} se nenhum nó coube
10. Após o delay, nó 4 (PDF): envia via API REST do Chatwit com Agent Bot token
11. Nó 5 (texto final): envia via API REST do Chatwit
12. Fim do flow
```

### O que muda em cada lado

| Lado | O que muda |
|------|-----------|
| **Chatwit** | Agent Bot config + dispatcher interactive + aceitar `{"status":"accepted"}` sem erro |
| **Socialwise** | Conectar FlowOrchestrator ao webhook + config do Agent Bot token |

---

## 3. Requisito 1: Agent Bot — Zero Código (Config)

### O que é

O Chatwoot (e portanto o Chatwit) já tem um mecanismo nativo chamado **Agent Bot**. É uma entidade que:
- Recebe webhooks quando mensagens chegam (via `outgoing_url`)
- Pode enviar mensagens via API REST usando um `api_access_token` auto-gerado
- Tem permissões restritas: só `messages#create`, `conversations#toggle_status`, `assignments#create`

### Como criar

1. Acessar o **Super Admin** do Chatwit: `https://SEU_CHATWIT/super_admin/agent_bots`
2. Criar novo Agent Bot:
   - **Nome**: `Socialwise Bot`
   - **Descrição**: `Bot de automação Socialwise — entrega mensagens assíncronas`
   - **Outgoing URL**: `https://socialwise.witdev.com.br/api/integrations/webhooks/socialwiseflow` (opcional — o Flow Engine pode não precisar deste webhook)
3. Após criar, um `access_token` é gerado automaticamente via `AccessTokenable` concern

### Código Ruby relevante (já existe — nada a alterar)

**Modelo** — `app/models/agent_bot.rb`:
```ruby
class AgentBot < ApplicationRecord
  include AccessTokenable    # ← gera api_access_token automaticamente
  has_many :messages, as: :sender  # ← mensagens do bot ficam com sender_type: 'AgentBot'
  # ...
end
```

**Auth** — `app/controllers/concerns/access_token_auth_helper.rb`:
```ruby
BOT_ACCESSIBLE_ENDPOINTS = {
  'api/v1/accounts/conversations/messages' => ['create'],  # ← pode criar mensagens
  'api/v1/accounts/conversations' => %w[toggle_status toggle_priority create update custom_attributes],
  'api/v1/accounts/conversations/assignments' => ['create']
}.freeze
```

### Como o Socialwise usará

```http
POST /api/v1/accounts/{account_id}/conversations/{conversation_id}/messages
Headers:
  api_access_token: {token_do_agent_bot}
  Content-Type: application/json
Body:
  {
    "content": "Olá! Aqui está o documento solicitado.",
    "message_type": "outgoing"
  }
```

### Configuração no Socialwise

Adicionar no `.env` do Socialwise:
```env
CHATWIT_AGENT_BOT_TOKEN=abc123_token_gerado
CHATWIT_BASE_URL=https://seu-chatwit.exemplo.com
CHATWIT_ACCOUNT_ID=1
```

O `ChatwitDeliveryService` (já implementado em `services/flow-engine/chatwit-delivery-service.ts`) já usa esses valores:
```typescript
// services/flow-engine/chatwit-delivery-service.ts
headers: { api_access_token: process.env.CHATWIT_AGENT_BOT_TOKEN }
```

### Complexidade: Nenhuma (apenas configuração no painel admin)

---

## 4. Requisito 2: Dispatcher Interactive (Código Ruby)

### Problema

Quando o Socialwise envia uma mensagem interativa (botões, listas) via API REST do Agent Bot, o `MessageBuilder` cria a `Message` com `content_type: 'integrations'` e `content_attributes: { interactive: {...} }`. Até aí, tudo funciona — o registro é salvo no banco.

O problema é no **envio para o WhatsApp**. O pipeline de saída:

```
Message.create → send_reply → SendReplyJob → SendOnWhatsappService → WhatsappCloudService.send_message()
```

E o `send_message()` **não sabe** rotear `content_type: integrations`:

```ruby
# app/services/whatsapp/providers/whatsapp_cloud_service.rb — ATUAL
def send_message(phone_number, message)
  if message.attachments.present?
    send_attachment_message(phone_number, message)
  elsif message.content_type == 'input_select'
    send_interactive_text_message(phone_number, message)
  else
    send_text_message(phone_number, message)  # ← interativas caem aqui como TEXTO!
  end
end
```

### Solução: Adicionar branch para `integrations`

O método `send_interactive_payload` **já existe** no mesmo arquivo (linha 42). Basta rotear para ele:

```ruby
# app/services/whatsapp/providers/whatsapp_cloud_service.rb — PROPOSTA
def send_message(phone_number, message)
  @message = message

  if message.attachments.present?
    send_attachment_message(phone_number, message)
  elsif message.content_type == 'input_select'
    send_interactive_text_message(phone_number, message)
  elsif message.content_type == 'integrations' && message.content_attributes&.dig('interactive').present?
    # SocialWise Flow: mensagem interativa enviada via API REST (Agent Bot)
    interactive_payload = message.content_attributes['interactive']
    send_interactive_payload(phone_number, message, interactive_payload)
  else
    send_text_message(phone_number, message)
  end
end
```

### O que essa mudança faz

| Cenário | Antes | Depois |
|---------|-------|--------|
| Agent Bot envia texto puro | ✅ Funciona | ✅ Funciona |
| Agent Bot envia attachment | ✅ Funciona | ✅ Funciona |
| Agent Bot envia interativa (`integrations` + `interactive`) | ❌ Envia como texto puro | ✅ Roteia para `send_interactive_payload` |
| SocialWise Flow sync (com `skip_send_reply`) | ✅ Funciona (bypass) | ✅ Funciona (não afetado) |

### Arquivo a alterar

| Arquivo | Linha | Mudança |
|---------|-------|---------|
| `app/services/whatsapp/providers/whatsapp_cloud_service.rb` | 2-12 | Adicionar `elsif integrations` (~4 linhas) |

### Complexidade: Baixa (~15min de implementação)

### Alternativa: `skip_send_reply` + 2 chamadas

Se preferir **não mexer no dispatcher**, o Socialwise pode:
1. Criar mensagem com `additional_attributes: { skip_send_reply: true }` (impede `SendReplyJob`)
2. Buscar phone_number e channel via API
3. Chamar `send_interactive_payload` diretamente via algum endpoint customizado

**Não recomendado**: mais complexo, mais frágil, mais acoplamento.

---

## 5. Requisito 3: `button_reply.id` no Webhook (Verificação)

### Status: Provavelmente já funciona

O código Ruby já faz tudo necessário. Verificação arquivo a arquivo:

### A) Mensagem de entrada — `button_reply.id` é extraído e salvo

**Arquivo**: `app/services/whatsapp/incoming_message_base_service.rb` — linhas 168-199:

```ruby
def extract_interactive_data(message)
  return {} unless message[:type] == 'interactive'
  interactive_data = {}

  if message.dig(:interactive, :button_reply)
    button_reply = message[:interactive][:button_reply]
    interactive_data[:button_reply] = {
      id: button_reply[:id],       # ← preserva o ID do botão
      title: button_reply[:title]
    }
    interactive_data[:interaction_type] = 'button_reply'
  end
  # ... list_reply também
  interactive_data
end
```

### B) Webhook payload — `content_attributes` é incluído

**Arquivo**: `app/models/message.rb` — linhas 172-190:

```ruby
def webhook_data
  data = {
    content_attributes: content_attributes,  # ← inclui button_reply
    content_type: content_type,
    # ...
  }
end
```

### C) SocialWise Flow — `button_reply.id` é extraído do payload

**Arquivo**: `lib/integrations/socialwise_flow/processor_service.rb` — linhas 1609-1620:

```ruby
def extract_interaction_data(message)
  content_attrs = message.content_attributes.with_indifferent_access
  if content_attrs[:button_reply].present?
    data[:button_id] = content_attrs[:button_reply][:id]  # ← envia pro Socialwise
    data[:interaction_type] = 'button_reply'
  end
  # ...
end
```

### D) Detecção de interactive reply — processa sem debounce

**Arquivo**: `lib/integrations/socialwise_flow/processor_service.rb` — linhas 62-82:

```ruby
def interactive_reply?(message)
  has_button_reply = content_attrs['button_reply'].present?
  has_list_reply = content_attrs['list_reply'].present?
  # ...
  # Se for interactive, processa IMEDIATAMENTE (sem debounce)
end
```

### Ação necessária: Apenas teste de verificação E2E

```
1. Enviar mensagem interativa com botões via WhatsApp
2. Usuário clica no botão
3. Verificar nos logs do Chatwit: button_reply.id presente
4. Verificar no payload recebido pelo Socialwise: button_id presente
```

### Complexidade: Nenhuma (apenas verificação)

---

## 6. Requisito 4: ProcessorService — Aceitar Resposta Async

### Problema

Hoje o `get_response()` espera que **toda resposta** do Socialwise venha no body do HTTP dentro de 30s. Se o Socialwise precisar de mais tempo (flow com delay, IA lenta), o HTTP dá timeout e a resposta se perde.

### Solução: Aceitar `{"status":"accepted"}` como resposta válida

Com a arquitetura Dual-Mode, o Socialwise pode retornar dois tipos de resposta:

**Modo Sync** (flow rápido — cabem nos 28s):
```json
{
  "text": "Olá! Como posso ajudar?",
  "mapped": {
    "whatsapp": {
      "type": "interactive",
      "interactive": { "type": "button", "body": {"text":"..."}, "action": {"buttons":[...]} }
    }
  }
}
```

**Modo Async** (flow longo — vai continuar após a resposta HTTP):
```json
{
  "status": "accepted",
  "async": true
}
```

### Mudança no `process_response`

**Arquivo**: `lib/integrations/socialwise_flow/processor_service.rb` — dentro de `process_response`:

```ruby
def process_response(message, response)
  return if response.blank?

  # NOVO: Se o Socialwise indicou que vai processar async, não fazer nada.
  # As mensagens virão via API REST do Agent Bot.
  if response['status'] == 'accepted' && response['async'] == true
    Rails.logger.info '[SOCIALWISE-FLOW] Async processing accepted — messages will arrive via Agent Bot API'
    return
  end

  # ... resto da lógica atual (sem mudança)
end
```

### Mudança opcional: Timeout configurável

Hoje o timeout é hardcoded em 30s. Tornar configurável via ENV:

```ruby
# ANTES (linha 334):
response = HTTParty.post(url, headers: headers, body: payload.to_json, timeout: 30)

# DEPOIS:
timeout_seconds = ENV.fetch('SOCIALWISE_FLOW_TIMEOUT', '30').to_i
response = HTTParty.post(url, headers: headers, body: payload.to_json, timeout: timeout_seconds)
```

Isso permite ajustar sem redeploy. Mas **não é a solução principal** — a solução é o modo async.

### Arquivos a alterar

| Arquivo | Mudança | Complexidade |
|---------|---------|--------------|
| `processor_service.rb` — `process_response` | Adicionar early return para `status:accepted` | Baixa (~3 linhas) |
| `processor_service.rb` — `get_response` | Timeout via ENV (opcional) | Baixa (~2 linhas) |

---

## 7. Requisito 5: Wiring no Socialwise (FlowOrchestrator)

### Estado atual

O `FlowOrchestrator` e `FlowExecutor` estão implementados mas **não conectados ao webhook real**. O webhook do SocialWise Flow (`app/api/integrations/webhooks/socialwiseflow/route.ts`) usa o pipeline de classificação (Flash Intent / Performance Bands), não o Flow Engine.

### O que precisa ser conectado

```
Webhook SocialWise Flow (route.ts)
    │
    ├─ HOJE: Flash Intent → Mapeamento → template response (sync ≤30s)
    │
    └─ NOVO: Se tem Flow associado ao intent/inbox:
              FlowOrchestrator.handle(payload) → Dual-mode response
```

### Integração proposta

No handler do webhook (Socialwise), adicionar lógica:

```typescript
// Pseudocódigo dentro do webhook handler
const flowMapping = await findFlowForIntent(intent, inboxId);

if (flowMapping) {
  // Usa o Flow Engine com deadline-first
  const orchestrator = new FlowOrchestrator();
  const syncPayload = await orchestrator.handle({
    conversationId,
    contactPhone,
    messageContent,
    inboxId,
    channelType,
    interactionData, // button_id, etc
  });

  if (syncPayload) {
    // Respondeu dentro dos 28s — retorna sync no body
    return NextResponse.json(syncPayload);
  } else {
    // Flow está rodando async — já enviou/vai enviar via API
    return NextResponse.json({ status: 'accepted', async: true });
  }
} else {
  // Sem flow — usar pipeline atual (Flash Intent)
  // ...
}
```

### Variáveis de ambiente necessárias no Socialwise

```env
# Já existem no ChatwitDeliveryService
CHATWIT_BASE_URL=https://seu-chatwit.exemplo.com
CHATWIT_ACCOUNT_ID=1
CHATWIT_AGENT_BOT_TOKEN=abc123_token_gerado
```

### TODOs no código do Socialwise (já sinalizados)

| Arquivo | Linha | TODO |
|---------|-------|------|
| `services/flow-engine/flow-orchestrator.ts` | 281 | Integrar com IntentProcessor para buscar mapeamentos |
| `services/flow-engine/flow-executor.ts` | 461 | Implementar chamada à API de tags do Chatwit |
| `services/flow-engine/flow-executor.ts` | 489 | Implementar assign via API Chatwit |
| `services/flow-engine/flow-executor.ts` | 511 | Implementar emoji reaction via API |

### Complexidade: Média (requer conectar peças já implementadas)

---

## 8. Contrato JSON — Formatos de Resposta

### Formato 1: Resposta Sync (como hoje, sem mudança)

O Socialwise responde dentro de 28s com o payload completo:

```json
{
  "text": "Olá! Como posso ajudar?",
  "mapped": {
    "whatsapp": {
      "type": "interactive",
      "interactive": {
        "type": "button",
        "body": { "text": "Olá! Como posso ajudar?" },
        "action": {
          "buttons": [
            { "type": "reply", "reply": { "id": "btn_suporte", "title": "Suporte" } },
            { "type": "reply", "reply": { "id": "btn_vendas", "title": "Vendas" } }
          ]
        }
      }
    }
  },
  "action": "handoff"
}
```

**Comportamento do Chatwit**: `process_response()` cria mensagem e envia normalmente.

### Formato 1.1: Resposta Sync `button_reaction` (Reação a Botão)

Quando o usuário clica num botão e o Flow Engine precisa **reagir com emoji e/ou enviar um texto em contexto**, o Socialwise retorna o formato `button_reaction`. O Chatwit deve rotear para `process_button_reaction` que:
1. Envia emoji reaction na mensagem do botão clicado (se `reaction_emoji` presente)
2. Envia texto como resposta em contexto / quoted reply (se `response_text` presente)

**Variante 1: Emoji + Texto (ambos)**
```json
{
  "action_type": "button_reaction",
  "emoji": "❤️",
  "text": "texto resposta em contexto do botão",
  "whatsapp": {
    "message_id": "wamid.HBgMNTU4...",
    "reaction_emoji": "❤️",
    "response_text": "texto resposta em contexto do botão"
  }
}
```

**Variante 2: Só Emoji (sem texto)**
```json
{
  "action_type": "button_reaction",
  "emoji": "👍",
  "whatsapp": {
    "message_id": "wamid.HBgMNTU4...",
    "reaction_emoji": "👍"
  }
}
```

**Variante 3: Só Texto em contexto (sem emoji)**
```json
{
  "action_type": "button_reaction",
  "text": "resposta em contexto do botão",
  "whatsapp": {
    "message_id": "wamid.HBgMNTU4...",
    "response_text": "resposta em contexto do botão"
  }
}
```

**Campos por canal** (mesma estrutura, chave diferente):

| Canal | Chave | Campos |
|-------|-------|--------|
| WhatsApp | `whatsapp` | `message_id`, `reaction_emoji?`, `response_text?` |
| Instagram | `instagram` | `message_id`, `reaction_emoji?`, `response_text?` |
| Facebook | `facebook` | `message_id`, `reaction_emoji?`, `response_text?` |

**Comportamento esperado do Chatwit (`process_button_reaction`)**:

```ruby
def process_button_reaction(response)
  channel_data = response['whatsapp'] || response['instagram'] || response['facebook']
  return unless channel_data

  message_id = channel_data['message_id']

  # 1. Enviar emoji reaction (se presente)
  if channel_data['reaction_emoji'].present?
    send_reaction(message_id, channel_data['reaction_emoji'])
  end

  # 2. Enviar texto como quoted reply / resposta em contexto (se presente)
  if channel_data['response_text'].present?
    send_quoted_reply(message_id, channel_data['response_text'])
  end
end
```

> **IMPORTANTE**: O `message_id` é o `wamid` (WhatsApp Message ID) / `source_id` da mensagem
> do botão que o usuário clicou. É usado como alvo da reação e como contexto do quoted reply.

**Ação necessária no Chatwit**: Implementar `process_button_reaction` no `ProcessorService` que suporte as 3 variantes (emoji-only, text-only, ambos). Se já existe handler para emoji+texto, verificar se funciona com campos opcionais.

### Formato 2: Resposta Async Accepted (NOVO)

O Socialwise vai processar o flow async:

```json
{
  "status": "accepted",
  "async": true
}
```

**Comportamento do Chatwit**: `process_response()` faz early return. Nenhuma mensagem é criada. As mensagens virão depois via API REST:

```http
POST /api/v1/accounts/1/conversations/42/messages
Headers:
  api_access_token: abc123_token_gerado
  Content-Type: application/json

# Mensagem 1 — texto
{"content": "Olá! Aqui está o resultado da análise.", "message_type": "outgoing"}

# Mensagem 2 — interativa com botões
{
  "content": "Escolha uma opção:",
  "message_type": "outgoing",
  "content_type": "integrations",
  "content_attributes": {
    "interactive": {
      "type": "button",
      "body": { "text": "Escolha uma opção:" },
      "action": {
        "buttons": [
          { "type": "reply", "reply": { "id": "btn_aprovar", "title": "Aprovar" } },
          { "type": "reply", "reply": { "id": "btn_rejeitar", "title": "Rejeitar" } }
        ]
      }
    }
  }
}

# Mensagem 3 — PDF (multipart/form-data)
# Content-Type: multipart/form-data
# file: documento.pdf
# content: "Segue o documento solicitado."
# message_type: outgoing
```

### Formato 3: Resposta Híbrida (sync parcial + async continuação)

O Socialwise responde sync com as primeiras mensagens, e continua async com o resto:

```json
{
  "text": "Analisando seus documentos, um momento...",
  "mapped": {
    "whatsapp": {
      "type": "text",
      "text": { "body": "Analisando seus documentos, um momento..." }
    }
  }
}
```

**Depois**, via API REST, envia o resultado da análise (pode demorar 60s, 120s, etc).

**Comportamento do Chatwit**: `process_response()` processa normalmente a parte sync. As mensagens async chegam via API e seguem o pipeline normal.

---

## 9. Tabela Resumo de Mudanças

### Chatwit (Fork)

| # | O quê | Arquivo | Tipo | Complexidade | Fase |
|---|-------|---------|------|--------------|------|
| 1 | Criar Agent Bot + obter token | Admin panel `/super_admin/agent_bots` | Config | Nenhuma | 1 |
| 2 | Rotear `integrations` no dispatcher | `whatsapp_cloud_service.rb` L2-12 | Código Ruby | Baixa (~4 linhas) | 3 |
| 3 | Early return para `status:accepted` | `processor_service.rb` — `process_response` | Código Ruby | Baixa (~5 linhas) | 1 |
| 4 | Timeout configurável via ENV | `processor_service.rb` — `get_response` L334 | Código Ruby | Baixa (~2 linhas) | 1 |
| 5 | Verificar `button_reply.id` no webhook | Logs + teste manual | Verificação | Baixa | 3 |

### Socialwise

| # | O quê | Arquivo | Tipo | Complexidade | Fase |
|---|-------|---------|------|--------------|------|
| 6 | Config Agent Bot token no `.env` | `.env` | Config | Nenhuma | 1 |
| 7 | Testar `deliverText()` via API Chatwit | `chatwit-delivery-service.ts` | Teste | Baixa | 1 |
| 8 | Testar `deliverMedia()` via API Chatwit | `chatwit-delivery-service.ts` | Teste | Baixa | 1 |
| 9 | Conectar FlowOrchestrator ao webhook | `socialwiseflow/route.ts` | Código TS | Média | 2 |
| 10 | Implementar TODOs: tags, assign, emoji | `flow-executor.ts` | Código TS | Média | 4 |

### O que NÃO muda

- ❌ Webhook de entrada (Meta → Chatwit) — já funciona
- ❌ Modelo Message — já tem `content_type: integrations` e `content_attributes`
- ❌ `MessageBuilder` — já aceita `content_type` e `content_attributes`
- ❌ Auth Agent Bot — `AccessTokenAuthHelper` já suporta
- ❌ `skip_send_reply` — já funciona
- ❌ Pipeline SocialWise Flow existente — modo sync continua funcionando

---

## 10. Checklist de Validação

### Fase 1 — Infraestrutura

- [ ] Agent Bot criado no Chatwit (`/super_admin/agent_bots`)
- [ ] Token configurado no Socialwise (`CHATWIT_AGENT_BOT_TOKEN`)
- [x] `chatwit_base_url` e `account_id` enviados no payload do webhook ✅ **IMPLEMENTADO 2026-02-08**
- [x] `process_response` aceita `{"status":"accepted","async":true}` sem erro ✅ **IMPLEMENTADO 2026-02-08**
- [x] Timeout configurável via `SOCIALWISE_FLOW_TIMEOUT` ENV ✅ **IMPLEMENTADO 2026-02-08**
- [ ] Socialwise envia texto puro via API → mensagem aparece no chat
- [ ] Socialwise envia PDF via API (multipart) → arquivo aparece no chat
- [ ] Mensagens do Agent Bot aparecem com `sender_type: AgentBot`

### Fase 3 — Interactive via API

- [x] Branch `integrations` adicionado em `send_message()` do `whatsapp_cloud_service.rb` ✅
pode olhar em /home/wital/chatwitv4.10/app/services/whatsapp/providers/whatsapp_cloud_service.rb
 **IMPLEMENTADO 2026-02-08**
- [ ] Socialwise envia interativa (`content_type: integrations` + `content_attributes.interactive`) → botões aparecem no WhatsApp
- [ ] Usuário clica botão → `button_reply.id` chega no Chatwit
- [ ] `button_reply.id` chega no webhook do Socialwise (campo `button_id`)
- [ ] FlowOrchestrator retoma flow correto a partir do `button_id`

### Fase E2E — Flow Completo

- [ ] Mensagem chega → intent classificado → flow carregado
- [ ] Nó 1 (texto) → entregue sync no body da resposta
- [ ] Nó 2 (botões) → entregue sync no body
- [ ] Nó 3 (delay 10s) → força modo async
- [ ] Nó 4 (PDF) → entregue via API Agent Bot
- [ ] Nó 5 (texto final) → entregue via API Agent Bot
- [ ] Toda a conversa visível no Chatwit sem lacunas

---

## 11. Troubleshooting

### "Mensagem interativa chega como texto puro no WhatsApp"

**Causa**: `send_message()` não tem branch para `content_type: integrations`.  
**Fix**: Aplicar Requisito 2 — adicionar `elsif integrations` no dispatcher.

### "Timeout ao enviar flow com delay"

**Causa**: `get_response()` com timeout 30s fixo.  
**Fix**: Aplicar Requisito 4 — aceitar `status:accepted` + timeout via ENV.

### "Bot não consegue enviar mensagem via API"

**Causa**: Token do Agent Bot inválido ou não configurado.  
**Verificar**:
```bash
# No Chatwit — testar token
curl -X POST https://SEU_CHATWIT/api/v1/accounts/1/conversations/42/messages \
  -H "api_access_token: SEU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"content":"Teste","message_type":"outgoing"}'
```
Deve retornar 200 com o objeto da mensagem.

### "button_reply.id não chega no Socialwise"

**Verificar logs do Chatwit**:
```
[SOCIALWISE-FLOW] Extracted WhatsApp button_reply: {button_id: "btn_xxx", ...}
```

Se não aparece, verificar `extract_interactive_data` em `incoming_message_base_service.rb`.

### "Mensagens async aparecem fora de ordem"

**Causa**: O Socialwise envia várias mensagens via API em sequência rápida.  
**Fix**: Usar `await` sequencial no `FlowExecutor` (já implementado — `executeChain` é sequencial por design).

---

**Última atualização**: 22 de Fevereiro de 2026
**Versão**: 1.5.0
**Mantido por**: Equipe Socialwise / Chatwit

---

## 12. Campanhas em Massa (Flow Campaigns) — Informativo para o Chatwit

### Contexto

O Socialwise implementou um sistema de campanhas em massa que executa Flows para listas de contatos. A orquestração é 100% do lado Socialwise (BullMQ + Prisma). O Chatwit **não precisa implementar nada novo** — campanhas usam a mesma API Agent Bot já documentada nas seções anteriores.

### Como funciona

```
Socialwise (CampaignOrchestrator)
  ├─ Chunka contatos em batches de 50
  ├─ Enfileira no BullMQ (fila "flow-campaign")
  ├─ Worker executa FlowOrchestrator.executeFlowById() por contato
  └─ Flow entrega mensagens via API Agent Bot do Chatwit
      └─ POST /api/v1/accounts/{account_id}/conversations/.../messages
```

### O que o Chatwit vai receber

Campanhas enviam **muitas mensagens via API Agent Bot** em sequência. Para uma campanha de 500 contatos, o Chatwit receberá ~500+ chamadas à API de mensagens, espaçadas pelo rate limiting:

| Canal | Rate Limit | Msgs/hora |
|-------|-----------|-----------|
| WhatsApp | 30/min | 1000 |
| Instagram | 20/min | 500 |
| Facebook | 25/min | 800 |

### O que verificar no Chatwit

1. **Sidekiq não engargalar**: Cada mensagem criada via API dispara `SendReplyJob`. Com campanhas grandes (500+ contatos), garantir que o Sidekiq consegue processar a fila sem acumular
2. **Rate limiting do WhatsApp Cloud API**: O Chatwit deve respeitar os limites da Meta (80 msgs/seg para tier 4). Se o Chatwit já tem throttling próprio, não precisa mudar nada
3. **Conversações novas**: Campanhas podem enviar para contatos sem conversa prévia. O `conversationId: 0` no contexto Socialwise significa que **não há conversa pré-existente** — o Socialwise precisará criar/buscar a conversa via API antes de enviar

### Ponto de atenção: Conversas sem ID prévio

Hoje a campanha executa `FlowOrchestrator.executeFlowById()` com `conversationId: 0` (sem conversa). Para campanhas funcionarem, o Socialwise precisa:
1. Buscar/criar conversa no Chatwit antes de enviar mensagens
2. Ou usar um endpoint Chatwit que crie conversa + envie mensagem atomicamente

**Pergunta para a equipe Chatwit**: Existe um endpoint que cria conversa + envia primeira mensagem para um `contactPhone` novo, ou precisa de 2 chamadas separadas (criar conversa → enviar mensagem)?

### Nenhuma mudança necessária no Chatwit (por agora)

Tudo que as campanhas usam já está implementado:
- API Agent Bot para envio de mensagens
- Dispatcher interactive para botões
- Upload de mídia via blob_id

---

## 13. Dispatch de Templates WhatsApp via API Agent Bot (NECESSÁRIO)

### Contexto

O Socialwise envia templates WhatsApp oficiais (aprovados pela Meta) via API Agent Bot, usando `content_type: "template"`. Hoje o `send_message()` no `whatsapp_cloud_service.rb` **não tem branch para `content_type: 'template'`**, então o template cai no `else` e é enviado como texto puro.

### O que o Socialwise envia

```http
POST {chatwit_base_url}/api/v1/accounts/{account_id}/conversations/{conversation_display_id}/messages
Headers:
  api_access_token: {metadata.chatwit_agent_bot_token}
  Content-Type: application/json
Body:
  {
    "content": "[Template: satisfacao_oab]",
    "content_type": "template",
    "content_attributes": {
      "template_payload": {
        "messaging_product": "whatsapp",
        "to": "+558597550136",
        "type": "template",
        "template": {
          "name": "satisfacao_oab",
          "language": { "code": "pt_BR" },
          "components": [
            {
              "type": "body",
              "parameters": [
                { "type": "text", "parameter_name": "nome_lead", "text": "João" }
              ]
            }
          ]
        }
      }
    },
    "message_type": "outgoing"
  }
```

### O que o Chatwit precisa implementar

Adicionar um branch em `send_message()` no `whatsapp_cloud_service.rb` para rotear `content_type: 'template'` para o `send_template()` que **já existe** (linha 24):

```ruby
# app/services/whatsapp/providers/whatsapp_cloud_service.rb — PROPOSTA
def send_message(phone_number, message)
  @message = message

  # Support for Async Button Reaction (Emoji) — já existe
  if message.content_attributes&.dig('reaction_emoji').present? && message.content_attributes&.dig('reaction_message_id').present?
    send_reaction(phone_number, message.content_attributes['reaction_message_id'], message.content_attributes['reaction_emoji'])
  end

  if message.attachments.present?
    send_attachment_message(phone_number, message)
  elsif message.content_type == 'input_select'
    send_interactive_text_message(phone_number, message)
  elsif message.content_type == 'integrations' && message.content_attributes&.dig('interactive').present?
    interactive_payload = message.content_attributes['interactive']
    send_interactive_payload(phone_number, message, interactive_payload)
  elsif message.content_type == 'template' && message.content_attributes&.dig('template_payload').present?
    # ✅ NOVO: SocialWise Flow — template oficial enviado via Agent Bot API
    template_payload = message.content_attributes['template_payload']
    send_template_from_payload(phone_number, message, template_payload)
  else
    send_text_message(phone_number, message) unless message.content.blank?
  end
end

# NOVO método — envia template usando payload completo do Socialwise
def send_template_from_payload(phone_number, message, template_payload)
  @message = message

  # O payload já vem pronto no formato WhatsApp Cloud API
  # Só precisa substituir o phone_number pelo número real (o Chatwit sabe o correto)
  request_body = template_payload.deep_symbolize_keys
  request_body[:to] = phone_number

  Rails.logger.info "[SOCIALWISE-FLOW-WHATSAPP] send_template_from_payload: #{request_body[:template][:name]} → #{phone_number}"

  response = HTTParty.post(
    "#{phone_id_path}/messages",
    headers: api_headers,
    body: request_body.to_json
  )

  process_response(response, message)
end
```

### Resumo

| O quê | Arquivo | Complexidade |
|-------|---------|--------------|
| Branch `content_type: 'template'` no `send_message()` | `whatsapp_cloud_service.rb` L2-22 | Baixa (~3 linhas) |
| Método `send_template_from_payload()` | `whatsapp_cloud_service.rb` (novo) | Baixa (~15 linhas) |

### Benefício

Templates enviados pelo Flow Builder/Campanhas do Socialwise:
1. Aparecem como mensagem **outgoing** no chat do Chatwit
2. São enviados ao WhatsApp pelo pipeline padrão do Chatwit (retry, tracking, etc.)
3. Ficam registrados no histórico da conversa

---

## 14. Adicionar `contacts` ao BOT_ACCESSIBLE_ENDPOINTS (NECESSÁRIO)

### Contexto

O Socialwise precisa **buscar e criar contatos** via Agent Bot para campanhas em massa. Hoje o Agent Bot só tem acesso a `conversations` e `messages`, mas para campanhas com **contatos novos** (que nunca tiveram conversa no Chatwit), é necessário:

1. Buscar contato por `phone_number` (`contacts/search`)
2. Criar contato se não existe (`contacts` create)
3. Criar conversa para esse contato (já funciona)

Atualmente usamos o **token do UsuarioChatwit** (user token) como workaround, mas o ideal é tudo pelo bot token.

### O que o Chatwit precisa implementar

Adicionar endpoints de `contacts` ao `BOT_ACCESSIBLE_ENDPOINTS` em `app/controllers/concerns/access_token_auth_helper.rb`:

```ruby
# ANTES:
BOT_ACCESSIBLE_ENDPOINTS = {
  'api/v1/accounts/conversations/messages' => ['create'],
  'api/v1/accounts/conversations' => %w[toggle_status toggle_priority create update custom_attributes],
  'api/v1/accounts/conversations/assignments' => ['create']
}.freeze

# DEPOIS:
BOT_ACCESSIBLE_ENDPOINTS = {
  'api/v1/accounts/conversations/messages' => ['create'],
  'api/v1/accounts/conversations' => %w[toggle_status toggle_priority create update custom_attributes],
  'api/v1/accounts/conversations/assignments' => ['create'],
  'api/v1/accounts/contacts' => %w[search create],           # ✅ NOVO: campanhas em massa
  'api/v1/accounts/contacts/search' => ['index'],             # ✅ NOVO: buscar contato por phone
}.freeze
```

### Endpoints que o Socialwise usará

**Buscar contato por telefone:**
```http
GET /api/v1/accounts/{account_id}/contacts/search?q=%2B5585999001234&include_contacts=true
Headers:
  api_access_token: {metadata.chatwit_agent_bot_token}
```

**Criar contato novo:**
```http
POST /api/v1/accounts/{account_id}/contacts
Headers:
  api_access_token: {metadata.chatwit_agent_bot_token}
  Content-Type: application/json
Body:
  {
    "name": "João Silva",
    "phone_number": "+5585999001234",
    "inbox_id": 1
  }
```

### Resumo

| O quê | Arquivo | Complexidade |
|-------|---------|--------------|
| Adicionar `contacts` search/create ao `BOT_ACCESSIBLE_ENDPOINTS` | `access_token_auth_helper.rb` | Muito baixa (~2 linhas) |

### Benefício

- Bot token como **único token** para toda operação do Socialwise (mensagens, conversas, contatos)
- Elimina dependência do token do UsuarioChatwit para campanhas
- Segurança melhor: bot tem escopo limitado vs user token tem acesso total

### Workaround temporário (Socialwise)

Enquanto o Chatwit não implementar, o Socialwise usa `UsuarioChatwit.chatwitAccessToken` (user token) para buscar/criar contatos. O `ChatwitConversationResolver` já suporta trocar para bot token quando disponível — basta mudar o token passado no construtor.

---

## 15. Init do Agent Bot — Registrar token no Socialwise (NECESSÁRIO)

### Contexto

O Agent Bot do Chatwit é global (`account_id=NULL`) e seu token é auto-provisionado no startup (`config/initializers/socialwise_bot.rb`). O Socialwise precisa desse token e da base URL para:
- Campanhas em massa (não têm webhook, não recebem metadata)
- Qualquer operação assíncrona iniciada pelo Socialwise

Atualmente o token vem no `metadata` de cada webhook, mas campanhas não passam por webhook.

### O que o Chatwit precisa implementar

No `config/initializers/socialwise_bot.rb`, **após** auto-provisionar o bot, fazer uma chamada HTTP para registrar o token no Socialwise:

```ruby
# config/initializers/socialwise_bot.rb — ADICIONAR APÓS auto-provisionar

# Registrar token no Socialwise para campanhas em massa
socialwise_webhook_url = ENV.fetch('SOCIALWISE_WEBHOOK_URL', nil)
chatwit_webhook_secret = ENV.fetch('CHATWIT_WEBHOOK_SECRET', nil)

if socialwise_webhook_url.present? && chatwit_webhook_secret.present?
  begin
    response = HTTParty.post(
      "#{socialwise_webhook_url}/api/integrations/webhooks/socialwiseflow/init",
      headers: { 'Content-Type' => 'application/json' },
      body: {
        agent_bot_token: Chatwit::SocialwiseBot.token,
        base_url: ENV.fetch('FRONTEND_URL', 'https://chatwit.witdev.com.br'),
        secret: chatwit_webhook_secret
      }.to_json,
      timeout: 10
    )
    Rails.logger.info "[SOCIALWISE-INIT] Bot token registrado no Socialwise: #{response.code}"
  rescue StandardError => e
    Rails.logger.warn "[SOCIALWISE-INIT] Falha ao registrar bot token: #{e.message}"
    # Não bloqueia o startup — o Socialwise tem fallback para ENV
  end
end
```

### Endpoint do Socialwise (já implementado)

```http
POST {SOCIALWISE_WEBHOOK_URL}/api/integrations/webhooks/socialwiseflow/init
Headers:
  Content-Type: application/json
Body:
  {
    "agent_bot_token": "5rxTkF7gs9H9E9jqEW4fqeas",
    "base_url": "https://chatwit.witdev.com.br",
    "secret": "<CHATWIT_WEBHOOK_SECRET>"
  }
Response: 200 { "status": "ok" }
```

### Validação

O Socialwise valida o `secret` contra `CHATWIT_WEBHOOK_SECRET` (mesma variável já usada no webhook principal). Se inválido, retorna 401.

### Resumo

| O quê | Arquivo | Complexidade |
|-------|---------|--------------|
| Chamar init do Socialwise após provisionar bot | `config/initializers/socialwise_bot.rb` | Baixa (~15 linhas) |

### Fallback

O Socialwise tem 3 camadas de fallback:
1. **SystemConfig** (banco) — atualizado pelo init e por cada webhook recebido
2. **ENV** — `CHATWIT_AGENT_BOT_TOKEN` e `CHATWIT_BASE_URL`
3. **Webhook metadata** — cada chamada do Chatwit traz os valores

O init garante que o SystemConfig esteja populado **antes** de qualquer campanha ser disparada.

### Variável de ambiente necessária no Chatwit

```env
SOCIALWISE_WEBHOOK_URL=https://app.socialwise.com.br  # URL base do Socialwise (sem /api/...)
```

Se já existir (usado pelo webhook), não precisa adicionar.

---

## Changelog

### v1.8.0 (2026-02-22) - Init do Agent Bot no Socialwise — ✅ IMPLEMENTADO

**Seção 15 — Implementado em 22/02/2026.**

No startup do bot, o Chatwit agora chama `POST /api/integrations/webhooks/socialwiseflow/init` enviando `agent_bot_token` + `base_url` + `secret`. O Socialwise persiste em `SystemConfig` para uso em campanhas em massa (sem depender de webhook).

**Arquivo modificado:**
- `config/initializers/socialwise_bot.rb`: Adicionada chamada HTTP ao Socialwise após auto-provisionamento do bot. Usa `SOCIALWISE_WEBHOOK_URL`, `CHATWIT_WEBHOOK_SECRET` e `FRONTEND_URL`. Falha silenciosa (warn no log) — não bloqueia startup

### v1.7.0 (2026-02-22) - BOT_ACCESSIBLE_ENDPOINTS: contacts — ✅ IMPLEMENTADO

**Seção 14 — Implementado em 22/02/2026.**

Adicionado `contacts` (search, create, show) ao `BOT_ACCESSIBLE_ENDPOINTS` para que o Agent Bot possa buscar/criar contatos em campanhas em massa. Elimina workaround com user token.

**Arquivo modificado:**
- `app/controllers/concerns/access_token_auth_helper.rb`: Adicionado `'api/v1/accounts/contacts' => %w[search create show]` ao hash `BOT_ACCESSIBLE_ENDPOINTS`

### v1.6.0 (2026-02-22) - Dispatch de Templates via Agent Bot — ✅ IMPLEMENTADO

**Seção 13 — Implementado em 22/02/2026.**

O Chatwit agora roteia `content_type: "template"` no `send_message()` para envio direto de templates WhatsApp oficiais via API Agent Bot.

**Arquivo modificado:**
- `app/services/whatsapp/providers/whatsapp_cloud_service.rb`:
  - Branch `elsif message.content_type == 'template'` adicionado ao `send_message()`
  - Novo método `send_template_from_payload()` que envia o payload completo do SocialWise para a WhatsApp Cloud API

### v1.5.0 (2026-02-22) - Campanhas em Massa (Informativo)

**Nenhuma mudança no Chatwit** — apenas documentação informativa (Seção 12).

O Socialwise implementou campanhas em massa que disparam Flows para listas de contatos via BullMQ. As campanhas usam a API Agent Bot já existente para entregar mensagens. Rate limiting é controlado pelo Socialwise (30 msgs/min WhatsApp).

**Resposta à pergunta da Seção 12**: Não existe endpoint atômico para criar conversa + enviar primeira mensagem. São 2 chamadas separadas: `POST /api/v1/accounts/{id}/conversations` (criar conversa) → `POST /api/v1/accounts/{id}/conversations/{conv_id}/messages` (enviar mensagem). Com a v1.7.0, ambas as operações podem ser feitas via bot token.

### v1.1.0 (2026-02-08) - Implementação Chatwit

**Arquivos modificados:**

1. **`lib/integrations/socialwise_flow/processor_service.rb`**
   - Linha 334-335: Timeout configurável via `SOCIALWISE_FLOW_TIMEOUT` ENV (default: 30s)
   - Linha 363-368: Early return para resposta `{"status":"accepted","async":true}`
   - Linha 1602: Adiciona `chatwit_base_url` no metadata do payload (usa `FRONTEND_URL`)

2. **`app/services/whatsapp/providers/whatsapp_cloud_service.rb`**
   - Linhas 9-12: Branch para rotear `content_type: integrations` + `interactive` para `send_interactive_payload()`

**Variável de ambiente adicionada:**
```env
SOCIALWISE_FLOW_TIMEOUT=30  # Timeout em segundos (opcional, default: 30)
```

**Payload do webhook agora inclui:**
```json
{
  "metadata": {
    "account_id": 1,
    "conversation_id": 123,
    "chatwit_base_url": "https://seu-chatwit.exemplo.com"
  }
}
```
O SocialWise não precisa configurar `CHATWIT_BASE_URL` nem `CHATWIT_ACCOUNT_ID` - tudo vem no payload!

### v1.2.0 (2026-02-11) - Bot Global Auto-Provisionado + Fix 401

**Problema resolvido:** Socialwise recebia 401 Unauthorized ao enviar mensagens async via Agent Bot API.

**Causa raiz:** Bots globais (`account_id = NULL`) precisavam de um registro em `agent_bot_inboxes` para cada conta que queriam acessar. Sem esse registro, `account_accessible_for_bot?` rejeitava o request.

**Arquivos modificados:**

1. **`app/controllers/concerns/ensure_current_account_helper.rb`**
   - `account_accessible_for_bot?`: Bots globais (`account_id.nil?`) agora podem acessar qualquer conta

2. **`config/initializers/socialwise_bot.rb`** (NOVO)
   - Auto-provisiona um Agent Bot global chamado "Socialwise Bot" no startup
   - Token disponível via `Chatwit::SocialwiseBot.token`
   - Não precisa mais criar bot manualmente no Super Admin

3. **`lib/integrations/socialwise_flow/processor_service.rb`**
   - `metadata.chatwit_agent_bot_token`: Token do bot enviado automaticamente no payload do webhook
   - Socialwise não precisa mais de `CHATWIT_AGENT_BOT_TOKEN` no .env — pega do webhook

**O que o SocialWise precisa mudar:**
- Em vez de ler `process.env.CHATWIT_AGENT_BOT_TOKEN`, ler `payload.metadata.chatwit_agent_bot_token`
- O token é enviado em cada request do webhook, sempre atualizado

### v1.4.0 (2026-02-12) - Contrato `button_reaction` (3 variantes)

**O que foi adicionado:**

Documentação do formato `button_reaction` na Seção 8 (Contrato JSON — Formatos de Resposta).

O Socialwise envia `action_type: "button_reaction"` na resposta síncrona quando o usuário clica um botão que tem REACTION e/ou TEXT em contexto. **Três variantes**:

| Variante | Campos obrigatórios | Quando |
|----------|---------------------|--------|
| Emoji + Texto | `reaction_emoji` + `response_text` | Botão com REACTION + TEXT paralelos |
| Só Emoji | `reaction_emoji` | Botão com REACTION sem TEXT |
| Só Texto | `response_text` | Botão com TEXT em contexto sem REACTION |

**O que o Chatwit precisa implementar/verificar:**

1. `process_button_reaction` em `ProcessorService` deve:
   - Ler `response['action_type'] == 'button_reaction'`
   - Pegar dados do canal: `response['whatsapp']` (ou `instagram`/`facebook`)
   - Se `reaction_emoji` presente → enviar `MessageReaction` no `message_id`
   - Se `response_text` presente → enviar quoted reply no `message_id`
   - Ambos os campos são **opcionais** mas pelo menos um estará presente

2. O `message_id` no payload é o `wamid` / `source_id` da mensagem do botão clicado

**Nenhum arquivo Ruby modificado nesta versão** — apenas documentação do contrato.

### v1.3.0 (2026-02-11) - Fix 404 + Documentação Mídia + Upload Bot

**Problemas resolvidos:**

1. **404 ao enviar mensagem async:** Socialwise usava `conversation_id` (id interno do banco) na URL da API, mas o Chatwit espera `display_id`.
2. **422 ao enviar mídia:** Não existia documentação para envio de mídia via URL pública.
3. **Upload bloqueado para bots:** O endpoint `/upload` não estava na lista de endpoints acessíveis para Agent Bots.

**Arquivos modificados:**

1. **`lib/integrations/socialwise_flow/processor_service.rb`**
   - Novo campo `metadata.conversation_display_id` no payload do webhook
   - O Socialwise DEVE usar este campo (e não `conversation_id`) na URL da API

2. **`app/controllers/concerns/access_token_auth_helper.rb`**
   - Adicionado `'api/v1/accounts/upload' => ['create']` em `BOT_ACCESSIBLE_ENDPOINTS`
   - Agent Bots agora podem fazer upload de mídia via URL pública

**Fluxo correto para enviar mídia com URL pública:**
```
POST /api/v1/accounts/{account_id}/upload
  Body: { "external_url": "https://..." }
  → Retorna: { "blob_id": "signed_id...", "file_url": "..." }

POST /api/v1/accounts/{account_id}/conversations/{display_id}/messages
  Body: { "content": "...", "message_type": "outgoing", "attachments": ["signed_id..."] }
```

**ALERTA para o Socialwise — dois campos críticos no metadata:**
```json
{
  "metadata": {
    "conversation_id": 2724,           // ❌ NÃO usar na URL da API
    "conversation_display_id": 2514,   // ✅ USAR na URL da API
  }
}
```
