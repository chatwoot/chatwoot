# Contrato de Integração: Chatwit ↔ JusMonitor

**Data:** 2026-02-26
**Versão:** 1.0
**Responsável Chatwit (Ruby):** Equipe Chatwit
**Responsável JusMonitor (Python):** Equipe JusMonitor

---

## 1. Visão Geral

O JusMonitor é um CRM jurídico multi-tenant com backend FastAPI. O Chatwit é a plataforma de atendimento (Rails 7.1, fork Chatwoot v4.10) que recebe mensagens de WhatsApp, Instagram e outros canais.

**Objetivo:** Integrar o Chatwit como canal de entrada de leads e comunicação com clientes do JusMonitor, permitindo:

1. Leads criados automaticamente no JusMonitor quando um contato novo envia mensagem no Chatwit
2. Mensagens sincronizadas entre as plataformas
3. Tags do Chatwit controlam o estágio do lead no funil do JusMonitor
4. JusMonitor envia mensagens e aplica tags nos contatos via API do Chatwit
5. Notificações de eventos jurídicos (prazos, movimentações) enviadas ao cliente via Chatwit

---

## 2. Arquitetura da Integração

```
┌─────────────────────┐         ┌─────────────────────┐
│      CHATWIT         │         │     JUSMONITOR       │
│   (Ruby on Rails)    │         │     (FastAPI)        │
│                      │         │                      │
│  WhatsApp ──┐        │  HTTP   │                      │
│  Instagram ─┤ Inbox  ├────────►│ POST /webhooks/chatwit│
│  Telegram ──┘        │ Webhook │   (recebe eventos)   │
│                      │         │                      │
│  API v1 ◄────────────┤ HTTP   │◄── ChatwitClient     │
│  /contacts           │  API    │   (envia mensagens,  │
│  /messages           │         │    aplica tags)      │
│  /tags               │         │                      │
└─────────────────────┘         └─────────────────────┘
```

---

## 3. O que o Chatwit DEVE implementar (Ruby)

### 3.1. Registro da Integração JusMonitor

**Arquivo:** `config/integrations/apps.yml`

Adicionar a app `jusmonitor` no registro de integrações:

```yaml
jusmonitor:
  id: jusmonitor
  name: JusMonitor
  description: "Integração com CRM jurídico JusMonitor"
  logo: jusmonitor.png
  fields:
    - name: api_url
      type: text
      label: "URL da API JusMonitor"
      placeholder: "https://api.jusmonitor.com.br/api/v1"
    - name: api_key
      type: text
      label: "API Key do JusMonitor"
    - name: tenant_id
      type: text
      label: "Tenant ID no JusMonitor"
    - name: webhook_secret
      type: text
      label: "Webhook Secret (HMAC-SHA256)"
  hook_type: account
  allow_multiple_hooks: false
```

### 3.2. Webhook de Eventos para o JusMonitor

**Arquivo novo:** `lib/integrations/jusmonitor/processor_service.rb`

O Chatwit deve enviar webhooks para o JusMonitor nos seguintes eventos:

#### Evento: `message.received` (mensagem inbound de contato)

```json
{
  "event_type": "message.received",
  "timestamp": "2026-02-26T10:30:00Z",
  "account_id": 1,
  "contact": {
    "id": "chw_contact_12345",
    "name": "João Silva",
    "phone": "+5511999999999",
    "email": "joao@example.com",
    "tags": ["novo_lead", "urgente"],
    "custom_fields": {
      "cpf": "123.456.789-00",
      "campaign": "ads_2026"
    }
  },
  "message": {
    "id": "msg_67890",
    "direction": "inbound",
    "content": "Olá, preciso de ajuda com um processo trabalhista",
    "media_url": null,
    "channel": "whatsapp"
  },
  "conversation": {
    "id": 456,
    "display_id": 789,
    "status": "open",
    "inbox_id": 1
  },
  "tag": null,
  "metadata": {}
}
```

#### Evento: `tag.added` (tag aplicada a contato)

```json
{
  "event_type": "tag.added",
  "timestamp": "2026-02-26T11:00:00Z",
  "account_id": 1,
  "contact": {
    "id": "chw_contact_12345",
    "name": "João Silva",
    "phone": "+5511999999999",
    "email": "joao@example.com",
    "tags": ["novo_lead", "qualificado"],
    "custom_fields": {}
  },
  "message": null,
  "conversation": null,
  "tag": "qualificado",
  "metadata": {}
}
```

#### Evento: `tag.removed` (tag removida de contato)

```json
{
  "event_type": "tag.removed",
  "timestamp": "2026-02-26T11:05:00Z",
  "account_id": 1,
  "contact": {
    "id": "chw_contact_12345",
    "name": "João Silva",
    "phone": "+5511999999999",
    "email": null,
    "tags": ["qualificado"],
    "custom_fields": {}
  },
  "message": null,
  "conversation": null,
  "tag": "novo_lead",
  "metadata": {}
}
```

### 3.3. Assinatura do Webhook (Segurança)

Toda requisição webhook DEVE incluir o header:

```
X-Chatwit-Signature: sha256=<HMAC-SHA256 do body com webhook_secret>
```

**Implementação Ruby:**

```ruby
# lib/integrations/jusmonitor/signature.rb
module Integrations
  module Jusmonitor
    class Signature
      def self.generate(payload_body, secret)
        digest = OpenSSL::HMAC.hexdigest('SHA256', secret, payload_body)
        "sha256=#{digest}"
      end
    end
  end
end
```

### 3.4. API que o Chatwit DEVE expor para o JusMonitor consumir

O JusMonitor já possui um `ChatwitClient` (Python/httpx) que faz chamadas à API do Chatwit. Os endpoints abaixo DEVEM existir e funcionar conforme especificado.

#### 3.4.1. Enviar Mensagem

```
POST /api/v1/accounts/{account_id}/conversations/{conversation_id}/messages
Authorization: Bearer <agent_bot_token ou api_access_token>
Content-Type: application/json
```

**Request:**
```json
{
  "content": "Olá João, seu processo teve uma movimentação importante hoje.",
  "message_type": "outgoing",
  "content_type": "text"
}
```

**Response (200):**
```json
{
  "id": 12345,
  "content": "Olá João, seu processo teve uma movimentação importante hoje.",
  "message_type": "outgoing",
  "status": "sent",
  "created_at": "2026-02-26T12:00:00Z"
}
```

#### 3.4.2. Enviar Mensagem com Botões Interativos

```
POST /api/v1/accounts/{account_id}/conversations/{conversation_id}/messages
```

**Request:**
```json
{
  "content": "Detectamos uma movimentação no seu processo 0001234-56.2024.5.02.0001. O que deseja fazer?",
  "message_type": "outgoing",
  "content_type": "input_select",
  "content_attributes": {
    "items": [
      { "title": "Ver detalhes", "value": "ver_detalhes" },
      { "title": "Falar com advogado", "value": "falar_advogado" },
      { "title": "Ignorar", "value": "ignorar" }
    ]
  }
}
```

#### 3.4.3. Enviar Mensagem com Template WhatsApp

```
POST /api/v1/accounts/{account_id}/conversations/{conversation_id}/messages
```

**Request:**
```json
{
  "content": "",
  "message_type": "outgoing",
  "content_type": "template",
  "content_attributes": {
    "template_name": "jusmonitor_prazo_urgente",
    "template_params": ["João Silva", "0001234-56.2024.5.02.0001", "3 dias"]
  }
}
```

#### 3.4.4. Adicionar Tag a Contato

```
POST /api/v1/accounts/{account_id}/contacts/{contact_id}/tags
Authorization: Bearer <api_access_token>
Content-Type: application/json
```

**Request:**
```json
{
  "tag": "qualificado"
}
```

**Response (200):**
```json
{
  "status": "success"
}
```

#### 3.4.5. Remover Tag de Contato

```
DELETE /api/v1/accounts/{account_id}/contacts/{contact_id}/tags/{tag_name}
Authorization: Bearer <api_access_token>
```

**Response (200):**
```json
{
  "status": "success"
}
```

#### 3.4.6. Obter Contato

```
GET /api/v1/accounts/{account_id}/contacts/{contact_id}
Authorization: Bearer <api_access_token>
```

**Response (200):**
```json
{
  "id": 12345,
  "name": "João Silva",
  "phone_number": "+5511999999999",
  "email": "joao@example.com",
  "custom_attributes": {
    "cpf": "123.456.789-00"
  },
  "tags": ["qualificado", "urgente"],
  "created_at": "2026-01-15T08:00:00Z"
}
```

#### 3.4.7. Buscar Contato por Telefone

```
GET /api/v1/accounts/{account_id}/contacts/search?q=+5511999999999
Authorization: Bearer <api_access_token>
```

**Response (200):**
```json
{
  "payload": [
    {
      "id": 12345,
      "name": "João Silva",
      "phone_number": "+5511999999999",
      "email": "joao@example.com"
    }
  ]
}
```

#### 3.4.8. Listar Tags Disponíveis

```
GET /api/v1/accounts/{account_id}/labels
Authorization: Bearer <api_access_token>
```

**Response (200):**
```json
{
  "payload": [
    { "id": 1, "title": "novo_lead", "color": "#3B82F6" },
    { "id": 2, "title": "contatado", "color": "#6366F1" },
    { "id": 3, "title": "qualificado", "color": "#8B5CF6" },
    { "id": 4, "title": "proposta", "color": "#A855F7" },
    { "id": 5, "title": "negociacao", "color": "#D946EF" },
    { "id": 6, "title": "convertido", "color": "#10B981" },
    { "id": 7, "title": "urgente", "color": "#EF4444" },
    { "id": 8, "title": "consulta_processo", "color": "#F59E0B" },
    { "id": 9, "title": "solicita_peticao", "color": "#8B5CF6" },
    { "id": 10, "title": "follow_up", "color": "#6366F1" }
  ]
}
```

#### 3.4.9. Criar Contato

```
POST /api/v1/accounts/{account_id}/contacts
Authorization: Bearer <api_access_token>
Content-Type: application/json
```

**Request:**
```json
{
  "name": "Maria Souza",
  "phone_number": "+5521988887777",
  "email": "maria@example.com",
  "custom_attributes": {
    "cpf": "987.654.321-00",
    "jusmonitor_client_id": "uuid-do-cliente-no-jusmonitor"
  }
}
```

**Response (200):**
```json
{
  "id": 12346,
  "name": "Maria Souza",
  "phone_number": "+5521988887777",
  "email": "maria@example.com",
  "custom_attributes": {
    "cpf": "987.654.321-00",
    "jusmonitor_client_id": "uuid-do-cliente-no-jusmonitor"
  }
}
```

#### 3.4.10. Criar Conversa (para envio proativo)

```
POST /api/v1/accounts/{account_id}/conversations
Authorization: Bearer <api_access_token>
Content-Type: application/json
```

**Request:**
```json
{
  "contact_id": 12345,
  "inbox_id": 1,
  "status": "open",
  "additional_attributes": {
    "jusmonitor_case_id": "uuid-do-caso",
    "cnj_number": "0001234-56.2024.5.02.0001"
  }
}
```

---

## 4. Tags Obrigatórias (Chatwit deve pré-criar)

O Chatwit DEVE criar as seguintes labels no account ao ativar a integração JusMonitor:

### Tags de Estágio do Funil

| Tag | Cor | Descrição | Mapeia para Estágio |
|-----|-----|-----------|---------------------|
| `novo_lead` | `#3B82F6` | Lead novo, ainda não contatado | `novo` |
| `contatado` | `#6366F1` | Lead já foi contatado | `contatado` |
| `qualificado` | `#8B5CF6` | Lead qualificado pela IA ou manualmente | `qualificado` |
| `proposta` | `#A855F7` | Proposta enviada ao lead | `proposta` |
| `negociacao` | `#D946EF` | Em negociação | `negociacao` |
| `convertido` | `#10B981` | Lead convertido em cliente | `convertido` |

### Tags de Ação

| Tag | Cor | Descrição | Ação no JusMonitor |
|-----|-----|-----------|---------------------|
| `urgente` | `#EF4444` | Atendimento urgente | Prioridade crítica, escala imediata |
| `consulta_processo` | `#F59E0B` | Solicita consulta de processo | Dispara busca no DataJud |
| `solicita_peticao` | `#8B5CF6` | Solicita petição/documento | Dispara WriterAgent |
| `follow_up` | `#6366F1` | Agendar follow-up | Cria tarefa de acompanhamento |

### Tags de Status

| Tag | Cor | Descrição |
|-----|-----|-----------|
| `cliente_ativo` | `#10B981` | Cliente ativo no JusMonitor |
| `cliente_inativo` | `#6B7280` | Cliente inativo |
| `aguardando_documento` | `#F59E0B` | Aguardando documento do cliente |
| `prazo_proximo` | `#EF4444` | Prazo processual próximo (<7 dias) |

---

## 5. Processor Service (Ruby) - Implementação

**Arquivo:** `lib/integrations/jusmonitor/processor_service.rb`

```ruby
# lib/integrations/jusmonitor/processor_service.rb
module Integrations
  module Jusmonitor
    class ProcessorService
      WEBHOOK_EVENTS = %w[
        message.created
        conversation.created
        conversation.status_changed
      ].freeze

      def initialize(event_name:, hook:, event_data:)
        @event_name = event_name
        @hook = hook
        @event_data = event_data
        @account = hook.account
        @settings = hook.settings  # { api_url, api_key, tenant_id, webhook_secret }
      end

      def perform
        return unless WEBHOOK_EVENTS.include?(@event_name)

        case @event_name
        when 'message.created'
          handle_message_created
        when 'conversation.created'
          handle_conversation_created
        when 'conversation.status_changed'
          handle_conversation_status_changed
        end
      end

      private

      def handle_message_created
        message = @event_data[:message]
        return unless message.incoming?

        contact = message.conversation.contact
        conversation = message.conversation

        payload = build_message_payload(contact, message, conversation)
        send_webhook('message.received', payload)
      end

      def handle_conversation_created
        conversation = @event_data[:conversation]
        contact = conversation.contact

        payload = build_conversation_payload(contact, conversation)
        send_webhook('conversation.created', payload)
      end

      def handle_conversation_status_changed
        conversation = @event_data[:conversation]
        # Notifica JusMonitor quando conversa e resolvida/reaberta
        payload = build_status_payload(conversation)
        send_webhook('conversation.status_changed', payload)
      end

      def build_message_payload(contact, message, conversation)
        {
          contact: serialize_contact(contact),
          message: {
            id: "msg_#{message.id}",
            direction: message.incoming? ? 'inbound' : 'outbound',
            content: message.content,
            media_url: message.attachments.first&.file_url,
            channel: conversation.inbox.channel_type_short
          },
          conversation: {
            id: conversation.id,
            display_id: conversation.display_id,
            status: conversation.status,
            inbox_id: conversation.inbox_id
          }
        }
      end

      def serialize_contact(contact)
        {
          id: "chw_contact_#{contact.id}",
          name: contact.name,
          phone: contact.phone_number,
          email: contact.email,
          tags: contact_tags(contact),
          custom_fields: contact.custom_attributes || {}
        }
      end

      def contact_tags(contact)
        # Buscar labels aplicadas nas conversas do contato
        conversations = contact.conversations.where(account_id: @account.id)
        conversations.flat_map { |c| c.label_list }.uniq
      end

      def send_webhook(event_type, payload)
        body = {
          event_type: event_type,
          timestamp: Time.current.iso8601,
          account_id: @account.id,
          **payload,
          metadata: {}
        }.to_json

        signature = Signature.generate(body, @settings['webhook_secret'])
        api_url = @settings['api_url']

        HTTParty.post(
          "#{api_url}/webhooks/chatwit",
          body: body,
          headers: {
            'Content-Type' => 'application/json',
            'X-Chatwit-Signature' => signature,
            'X-Chatwit-Account-Id' => @account.id.to_s
          },
          timeout: 10
        )
      rescue StandardError => e
        Rails.logger.error("[JusMonitor] Webhook failed: #{e.message}")
        # Enfileirar para retry via Sidekiq
        Integrations::Jusmonitor::WebhookRetryJob.perform_in(
          30.seconds, @event_name, @hook.id, @event_data.to_json
        )
      end
    end
  end
end
```

---

## 6. Hook Listener (Ruby) - Registro de Eventos

**Arquivo a editar:** `app/listeners/hook_listener.rb`

Adicionar o JusMonitor na lista de integrações que escutam eventos:

```ruby
# Dentro de HookListener, adicionar:
def jusmonitor_hooks(account)
  account.hooks.where(app_id: 'jusmonitor', status: 'enabled')
end

# No método que despacha eventos, adicionar:
def process_jusmonitor_events(event_name, event_data)
  account = extract_account(event_data)
  return unless account

  jusmonitor_hooks(account).each do |hook|
    Integrations::Jusmonitor::ProcessorJob.perform_async(
      event_name, hook.id, event_data
    )
  end
end
```

---

## 7. Sidekiq Jobs (Ruby)

### 7.1. Processor Job

**Arquivo novo:** `app/jobs/integrations/jusmonitor/processor_job.rb`

```ruby
module Integrations
  module Jusmonitor
    class ProcessorJob
      include Sidekiq::Job
      sidekiq_options queue: :integrations, retry: 3

      def perform(event_name, hook_id, event_data)
        hook = Integrations::Hook.find(hook_id)
        ProcessorService.new(
          event_name: event_name,
          hook: hook,
          event_data: JSON.parse(event_data, symbolize_names: true)
        ).perform
      end
    end
  end
end
```

### 7.2. Webhook Retry Job

**Arquivo novo:** `app/jobs/integrations/jusmonitor/webhook_retry_job.rb`

```ruby
module Integrations
  module Jusmonitor
    class WebhookRetryJob
      include Sidekiq::Job
      sidekiq_options queue: :integrations, retry: 5

      # Backoff: 30s, 1min, 2min, 5min, 10min
      sidekiq_retry_in do |count|
        [30, 60, 120, 300, 600][count] || 600
      end

      def perform(event_name, hook_id, event_data_json)
        hook = Integrations::Hook.find(hook_id)
        event_data = JSON.parse(event_data_json, symbolize_names: true)

        ProcessorService.new(
          event_name: event_name,
          hook: hook,
          event_data: event_data
        ).perform
      end
    end
  end
end
```

---

## 8. Tag Sync via API (Ruby)

### 8.1. Tag Listener para Webhook

Quando uma tag/label é adicionada ou removida de uma conversa ou contato, notificar o JusMonitor:

**Arquivo novo:** `lib/integrations/jusmonitor/tag_sync_service.rb`

```ruby
module Integrations
  module Jusmonitor
    class TagSyncService
      STAGE_TAGS = %w[
        novo_lead contatado qualificado proposta negociacao convertido
      ].freeze

      ACTION_TAGS = %w[
        urgente consulta_processo solicita_peticao follow_up
      ].freeze

      def initialize(hook:, contact:, tag:, action:)
        @hook = hook
        @contact = contact
        @tag = tag
        @action = action  # :added ou :removed
      end

      def perform
        return unless relevant_tag?

        payload = {
          contact: serialize_contact(@contact),
          tag: @tag,
          message: nil,
          conversation: nil,
          metadata: {
            tag_category: tag_category
          }
        }

        event_type = @action == :added ? 'tag.added' : 'tag.removed'
        send_webhook(event_type, payload)
      end

      private

      def relevant_tag?
        STAGE_TAGS.include?(@tag) || ACTION_TAGS.include?(@tag)
      end

      def tag_category
        return 'stage' if STAGE_TAGS.include?(@tag)
        return 'action' if ACTION_TAGS.include?(@tag)
        'other'
      end

      def serialize_contact(contact)
        {
          id: "chw_contact_#{contact.id}",
          name: contact.name,
          phone: contact.phone_number,
          email: contact.email,
          tags: contact_current_tags,
          custom_fields: contact.custom_attributes || {}
        }
      end

      def contact_current_tags
        conversations = @contact.conversations.where(
          account_id: @hook.account_id
        )
        conversations.flat_map { |c| c.label_list }.uniq
      end

      def send_webhook(event_type, payload)
        body = {
          event_type: event_type,
          timestamp: Time.current.iso8601,
          account_id: @hook.account_id,
          **payload
        }.to_json

        signature = Signature.generate(body, @hook.settings['webhook_secret'])
        api_url = @hook.settings['api_url']

        HTTParty.post(
          "#{api_url}/webhooks/chatwit",
          body: body,
          headers: {
            'Content-Type' => 'application/json',
            'X-Chatwit-Signature' => signature
          },
          timeout: 10
        )
      end
    end
  end
end
```

---

## 9. Setup Automático de Tags (Ruby)

Quando a integração JusMonitor for ativada no account, criar automaticamente as tags:

**Arquivo novo:** `lib/integrations/jusmonitor/setup_service.rb`

```ruby
module Integrations
  module Jusmonitor
    class SetupService
      REQUIRED_LABELS = [
        # Estágios do funil
        { title: 'novo_lead',       color: '#3B82F6', description: 'Lead novo - JusMonitor' },
        { title: 'contatado',       color: '#6366F1', description: 'Lead contatado - JusMonitor' },
        { title: 'qualificado',     color: '#8B5CF6', description: 'Lead qualificado - JusMonitor' },
        { title: 'proposta',        color: '#A855F7', description: 'Proposta enviada - JusMonitor' },
        { title: 'negociacao',      color: '#D946EF', description: 'Em negociacao - JusMonitor' },
        { title: 'convertido',      color: '#10B981', description: 'Lead convertido em cliente - JusMonitor' },
        # Acoes
        { title: 'urgente',              color: '#EF4444', description: 'Atendimento urgente' },
        { title: 'consulta_processo',    color: '#F59E0B', description: 'Solicita consulta de processo' },
        { title: 'solicita_peticao',     color: '#8B5CF6', description: 'Solicita peticao/documento' },
        { title: 'follow_up',           color: '#6366F1', description: 'Agendar follow-up' },
        # Status
        { title: 'cliente_ativo',           color: '#10B981', description: 'Cliente ativo no JusMonitor' },
        { title: 'cliente_inativo',         color: '#6B7280', description: 'Cliente inativo' },
        { title: 'aguardando_documento',    color: '#F59E0B', description: 'Aguardando documento' },
        { title: 'prazo_proximo',           color: '#EF4444', description: 'Prazo processual proximo' },
      ].freeze

      def initialize(account:)
        @account = account
      end

      def perform
        REQUIRED_LABELS.each do |label_attrs|
          existing = @account.labels.find_by(title: label_attrs[:title])
          next if existing

          @account.labels.create!(label_attrs)
        end
      end
    end
  end
end
```

---

## 10. Templates WhatsApp Obrigatórios

O Chatwit deve aprovar os seguintes templates WhatsApp para uso pelo JusMonitor:

### Template 1: `jusmonitor_prazo_urgente`

```
Olá {{1}}, temos um aviso importante sobre seu processo {{2}}.

Existe um prazo que vence em {{3}}. Entre em contato com seu advogado para mais detalhes.

JusMonitor - Monitoramento Jurídico Inteligente
```

**Parâmetros:** `[nome_cliente, numero_cnj, prazo_dias]`

### Template 2: `jusmonitor_movimentacao`

```
Olá {{1}}, houve uma nova movimentação no seu processo {{2}}.

Resumo: {{3}}

Para mais detalhes, fale com seu advogado ou acesse o portal.

JusMonitor - Monitoramento Jurídico Inteligente
```

**Parâmetros:** `[nome_cliente, numero_cnj, resumo_movimentacao]`

### Template 3: `jusmonitor_boas_vindas`

```
Olá {{1}}, bem-vindo ao escritório {{2}}!

Seu cadastro foi realizado com sucesso. A partir de agora, você receberá atualizações sobre seus processos por aqui.

Se tiver dúvidas, é só enviar uma mensagem.

JusMonitor - Monitoramento Jurídico Inteligente
```

**Parâmetros:** `[nome_cliente, nome_escritorio]`

### Template 4: `jusmonitor_briefing_diario`

```
Bom dia {{1}}! Aqui está o resumo do dia:

{{2}}

Para detalhes completos, acesse o painel JusMonitor.
```

**Parâmetros:** `[nome_advogado, resumo_briefing]`

---

## 11. Mapeamento de Campos (contact_id)

O JusMonitor usa o campo `chatwit_contact_id` nos modelos Lead e Client. O formato DEVE ser:

```
chw_contact_{id_numerico_do_chatwit}
```

**Exemplo:** Contato com `id: 12345` no Chatwit → `chatwit_contact_id: "chw_contact_12345"` no JusMonitor.

O Chatwit DEVE usar este mesmo formato em todos os webhooks no campo `contact.id`.

---

## 12. Custom Attributes do Contato

O Chatwit deve permitir armazenar os seguintes `custom_attributes` nos contatos:

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `jusmonitor_client_id` | string (UUID) | ID do cliente no JusMonitor |
| `jusmonitor_lead_id` | string (UUID) | ID do lead no JusMonitor |
| `jusmonitor_tenant_id` | string (UUID) | Tenant do JusMonitor |
| `cpf` | string | CPF do contato |
| `cnpj` | string | CNPJ (pessoa jurídica) |
| `oab` | string | Registro OAB (se advogado) |

O JusMonitor pode definir esses campos via `POST /contacts` ou `PUT /contacts/{id}`.

---

## 13. Rate Limiting

| Endpoint | Limite | Janela |
|----------|--------|--------|
| API geral | 100 req | 1 minuto |
| Envio de mensagens | 60 req | 1 minuto |
| Webhooks (Chatwit → JusMonitor) | Sem limite* | - |

*O Chatwit deve enviar webhooks sem rate limiting próprio, mas com retry e backoff em caso de falha.

---

## 14. Autenticação

### API do Chatwit (JusMonitor consumindo)

```
Authorization: Bearer <api_access_token>
```

O `api_access_token` é gerado no painel do Chatwit, seção Integrações, ao ativar o JusMonitor.

### Webhooks do Chatwit (para JusMonitor)

```
X-Chatwit-Signature: sha256=<HMAC-SHA256>
X-Chatwit-Account-Id: <account_id>
Content-Type: application/json
```

---

## 15. Tratamento de Erros

### Respostas esperadas do JusMonitor ao receber webhook:

| Status | Significado | Ação do Chatwit |
|--------|-------------|-----------------|
| `200` | Sucesso | Nenhuma |
| `401` | Assinatura inválida | Log de erro, NÃO retentar |
| `422` | Payload inválido | Log de erro, NÃO retentar |
| `429` | Rate limit | Retentar com backoff (30s, 1min, 2min) |
| `500` | Erro interno | Retentar com backoff (30s, 1min, 2min, 5min, 10min) |
| Timeout (>10s) | Sem resposta | Retentar com backoff |

**Máximo de retries:** 5 tentativas

---

## 16. Variáveis de Ambiente (Chatwit)

```bash
# Ativadas por account, salvas no hook.settings
# Não são variáveis globais - cada account configura a sua

# Para desenvolvimento/testes locais:
JUSMONITOR_TEST_API_URL=http://localhost:8000/api/v1
JUSMONITOR_TEST_API_KEY=dev-key-123
JUSMONITOR_TEST_TENANT_ID=00000000-0000-0000-0000-000000000001
JUSMONITOR_TEST_WEBHOOK_SECRET=dev-secret-456
```

---

## 17. Estrutura de Arquivos (Ruby) - Checklist

```
lib/integrations/jusmonitor/
├── processor_service.rb      # Processa eventos e envia webhooks
├── tag_sync_service.rb       # Sincroniza tags com JusMonitor
├── setup_service.rb          # Setup automático de labels
├── signature.rb              # Assinatura HMAC-SHA256
└── webhook_retry_job.rb      # Job de retry para webhooks

app/jobs/integrations/jusmonitor/
├── processor_job.rb          # Sidekiq job principal
└── webhook_retry_job.rb      # Sidekiq job de retry

# Arquivos existentes a editar:
config/integrations/apps.yml           # Adicionar jusmonitor
app/listeners/hook_listener.rb         # Registrar eventos JusMonitor
app/models/integrations/hook.rb        # Adicionar jusmonitor? helper
```

---

## 18. Fluxos Completos

### Fluxo 1: Novo Lead via WhatsApp

```
1. Cliente envia mensagem no WhatsApp
2. Chatwit recebe via Meta API → cria Contact + Conversation
3. HookListener detecta message.created
4. ProcessorJob enfileira no Sidekiq
5. ProcessorService monta payload message.received
6. POST webhook para JusMonitor com assinatura HMAC
7. JusMonitor cria Lead com source=chatwit, chatwit_contact_id
8. JusMonitor roda TriageAgent → calcula score
9. JusMonitor aplica tag via API: POST /contacts/{id}/tags → "qualificado"
10. Chatwit aplica label na conversa
11. TagSyncService detecta tag.added
12. Webhook tag.added para JusMonitor
13. JusMonitor atualiza estágio do lead para "qualificado"
```

### Fluxo 2: Notificação de Prazo Processual

```
1. Worker JusMonitor detecta prazo < 3 dias no DataJud
2. JusMonitor busca contato: GET /contacts/search?q=telefone
3. JusMonitor cria conversa: POST /conversations (se não existe aberta)
4. JusMonitor envia template: POST /messages com jusmonitor_prazo_urgente
5. JusMonitor aplica tag: POST /contacts/{id}/tags → "prazo_proximo"
6. Cliente recebe WhatsApp com o prazo
7. Cliente responde → webhook message.received para JusMonitor
8. JusMonitor processa resposta via IA
```

### Fluxo 3: Conversão Lead → Cliente

```
1. Advogado marca lead como "convertido" no JusMonitor
2. JusMonitor cria Client a partir do Lead
3. JusMonitor chama API Chatwit:
   a. PUT /contacts/{id} → adiciona custom_attribute jusmonitor_client_id
   b. POST /contacts/{id}/tags → "convertido"
   c. POST /contacts/{id}/tags → "cliente_ativo"
   d. DELETE /contacts/{id}/tags/novo_lead
4. JusMonitor envia template boas_vindas via POST /messages
5. Chatwit atualiza labels na conversa
```

---

## 19. Testes (Ruby)

A equipe Chatwit DEVE implementar os seguintes testes:

### RSpec

```ruby
# spec/lib/integrations/jusmonitor/processor_service_spec.rb
- Processar message.created de mensagem inbound
- Ignorar mensagem outbound
- Montar payload correto com contact, message, conversation
- Assinar webhook com HMAC-SHA256
- Retry via Sidekiq em caso de falha HTTP

# spec/lib/integrations/jusmonitor/tag_sync_service_spec.rb
- Enviar webhook tag.added para tags de estágio
- Enviar webhook tag.removed
- Ignorar tags não mapeadas

# spec/lib/integrations/jusmonitor/setup_service_spec.rb
- Criar labels obrigatórias ao ativar integração
- Não duplicar labels já existentes

# spec/lib/integrations/jusmonitor/signature_spec.rb
- Gerar assinatura HMAC-SHA256 válida
- Verificar assinatura
```

---

## 20. Cronograma Sugerido

| Fase | Escopo | Prazo |
|------|--------|-------|
| **Fase 1** | Setup integração (apps.yml, hook, labels) | 1 semana |
| **Fase 2** | Webhook de mensagens (processor_service) | 1 semana |
| **Fase 3** | Tag sync bidirecional | 1 semana |
| **Fase 4** | API endpoints (tags em contato, busca) | 1 semana |
| **Fase 5** | Templates WhatsApp + mensagens proativas | 1 semana |
| **Fase 6** | Testes + QA + ajustes | 1 semana |

**Total estimado: 6 semanas**

---

## 21. Critérios de Aceite

- [ ] Integração JusMonitor aparece em `config/integrations/apps.yml`
- [ ] Ativação da integração cria labels obrigatórias automaticamente
- [ ] Webhook `message.received` enviado com payload correto e assinatura HMAC
- [ ] Webhook `tag.added` e `tag.removed` enviados para tags mapeadas
- [ ] API `POST /contacts/{id}/tags` funciona corretamente
- [ ] API `DELETE /contacts/{id}/tags/{tag}` funciona corretamente
- [ ] API `GET /contacts/search` retorna contato por telefone
- [ ] API `POST /conversations` permite criar conversa proativa
- [ ] API `POST /messages` suporta text, input_select e template
- [ ] Templates WhatsApp aprovados e funcionais
- [ ] Custom attributes (`jusmonitor_client_id`, `cpf`, etc.) armazenados
- [ ] Retry com backoff para webhooks com falha
- [ ] Testes RSpec passando com cobertura > 80%
- [ ] Sem regressão nas funcionalidades existentes do Chatwit

---

## Assinaturas

| Equipe | Nome | Data |
|--------|------|------|
| Chatwit (Ruby) | __________________ | ___/___/2026 |
| JusMonitor (Python) | __________________ | ___/___/2026 |
