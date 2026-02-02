# Migration Etapa 1 - SocialWise Flow Integration

**Data Inicial:** 2026-01-30
**Última Atualização:** 2026-02-02 (Atualização 6)
**Versão Base:** Chatwoot 4.10.1
**Objetivo:** Integrar o SocialWise Flow (motor de fluxo com debounce e concatenação de mensagens)

---

## ⚠️ CORREÇÃO CRÍTICA (2026-01-31)

### Problema Identificado
A integração inicial foi configurada incorretamente usando `socialwise_chatwit` com `hook_type: account`, que exibia campos errados (Access Key, Secret Key) em vez do seletor de caixa de entrada.

### Solução Aplicada
Substituído `socialwise_chatwit` por `socialwise_flow` com `hook_type: inbox`:
- **Antes:** `socialwise_chatwit` (hook_type: account) - DEFASADO
- **Depois:** `socialwise_flow` (hook_type: inbox) - CORRETO

### Diferença Crítica
| Tipo | hook_type | Comportamento |
|------|-----------|---------------|
| `account` | Conecta à conta inteira | Mostra campos de API Key |
| `inbox` | Conecta à caixa de entrada específica | Mostra seletor de inbox |

---

## Resumo da Etapa 1

Esta etapa focou exclusivamente na **integração do SocialWise Flow** para o envio de mensagens via webhook para o SocialWise, com suporte a debounce e concatenação de mensagens.

### O que é o SocialWise Flow?

O SocialWise Flow é uma integração **por caixa de entrada (inbox)** que:
1. Envia mensagens recebidas para o webhook padrão do SocialWise
2. Suporta debounce para concatenar múltiplas mensagens antes de enviar
3. Recebe respostas do SocialWise e as exibe no dashboard

**Webhook Padrão:** `https://socialwise.witdev.com.br/api/integrations/webhooks/socialwiseflow`

### Escopo Realizado

- [x] Integração do fluxo de envio de mensagens para webhook SocialWise (WhatsApp/Instagram/Messenger)
- [x] Debounce de mensagens com Redis (concatenação antes do envio)
- [x] Processamento de respostas do SocialWise (mensagens interativas, templates)
- [x] **CORREÇÃO:** hook_type: inbox para conectar à caixa de entrada
- [x] Traduções pt_BR
- [x] Remoção de telemetria e Chat Support para privacidade

### Escopo Pendente (Etapa 2)

- [ ] Configuração de rotas e frontend de Stickers
- [ ] Melhorias de UI no dashboard

---

## Arquivos Modificados

### 1. Gemfile
**Caminho:** `Gemfile`
**Alteração:** Adicionada gem `httparty` para requisições HTTP

```ruby
gem 'httparty'
```

### 2. Redis Keys
**Caminho:** `lib/redis/redis_keys.rb`
**Alteração:** Adicionadas constantes para debounce do SocialWise

```ruby
## SocialWise Flow Debounce Keys
SOCIALWISE_DEBOUNCE_MESSAGES = 'SOCIALWISE_DEBOUNCE::%<conversation_id>d::MESSAGES'.freeze
SOCIALWISE_DEBOUNCE_FIRST_AT = 'SOCIALWISE_DEBOUNCE::%<conversation_id>d::FIRST_AT'.freeze
SOCIALWISE_DEBOUNCE_LAST_AT = 'SOCIALWISE_DEBOUNCE::%<conversation_id>d::LAST_AT'.freeze
SOCIALWISE_DEBOUNCE_LOCK = 'SOCIALWISE_DEBOUNCE::%<conversation_id>d::LOCK'.freeze
```

### 3. Hook Listener
**Caminho:** `app/listeners/hook_listener.rb`
**Alteração:** Configurado `socialwise_flow` no mapa de eventos suportados

```ruby
'socialwise_flow' => ['message.created', 'message.updated']
```

### 4. Hook Job
**Caminho:** `app/jobs/hook_job.rb`
**Alteração:** Processamento do SocialWise Flow

```ruby
when 'socialwise_flow'
  process_socialwise_flow_integration(hook, event_name, event_data)
```

### 5. Routes
**Caminho:** `config/routes.rb`
**Alteração:** Rota do socialwise_chatwit **REMOVIDA** - O `hooks_controller` genérico gerencia integrações do tipo inbox automaticamente

```ruby
# SocialWise Flow uses hooks_controller (hook_type: inbox)
```

### 6. Integration Apps Config
**Caminho:** `config/integration/apps.yml`
**Alteração:** Configuração completa do app `socialwise_flow` com `hook_type: inbox`

```yaml
socialwise_flow:
  id: socialwise_flow
  logo: socialwise-flow.png
  i18n_key: socialwise_flow
  action: /socialwise_flow
  hook_type: inbox                    # CRÍTICO: inbox para conectar à caixa de entrada
  allow_multiple_hooks: true
  settings_json_schema:
    {
      'type': 'object',
      'properties':
        {
          'endpoint': { 'type': 'string' },
          'access_token': { 'type': 'string' },
          'language': { 'type': 'string' }
        },
      'required': [],
      'additionalProperties': false,
    }
  settings_form_schema:
    [
      {
        'label': 'Endpoint',
        'type': 'text',
        'name': 'endpoint',
        'help': 'Ex.: https://socialwise.witdev.com.br/api/integrations/webhooks/socialwiseflow',
      },
      {
        'label': 'Access Token (opcional)',
        'type': 'text',
        'name': 'access_token',
      },
      {
        'label': 'Idioma',
        'type': 'text',
        'name': 'language',
        'default': 'pt-BR',
      },
    ]
  visible_properties: ['endpoint', 'language']
```

### 7. Locales - English
**Caminho:** `config/locales/en.yml`
**Alteração:** Traduções do SocialWise Flow

```yaml
socialwise_flow:
  name: 'SocialWise Flow'
  short_description: 'Automate with rich messages across Meta channels.'
  description: 'Connect SocialWise Flow as a bot to automate responses with prebuilt rich messages (buttons, headers, footers, images) on WhatsApp, Instagram, and Facebook.'
```

### 8. Locales - Portuguese BR
**Caminho:** `config/locales/pt_BR.yml`
**Alteração:** Traduções em português do SocialWise Flow

```yaml
socialwise_flow:
  name: 'SocialWise Flow'
  short_description: 'Automatize com mensagens ricas nos canais Meta.'
  description: 'Conecte o SocialWise Flow como um bot para automatizar respostas com mensagens ricas pré-configuradas (botões, cabeçalhos, rodapés, imagens) no WhatsApp, Instagram e Facebook.'
```

### 9. Inbox Model
**Caminho:** `app/models/inbox.rb`
**Alteração:** Incluído concern `SocialwiseCacheInvalidation`

### 10. Account Model
**Caminho:** `app/models/account.rb`
**Alteração:** Adicionada associação `has_many :account_feature_flags`

### 11. Chatwoot Hub (Telemetria)
**Caminho:** `lib/chatwoot_hub.rb`
**Alteração:** Bloqueio de telemetria quando `DISABLE_TELEMETRY=true`

```ruby
def self.sync_with_hub
  # CHATWIT: Block all hub communication when telemetry is disabled
  return {} if ENV['DISABLE_TELEMETRY'].to_s.downcase == 'true'
  # ...
end

def self.register_instance(company_name, owner_name, owner_email)
  # CHATWIT: Block registration when telemetry is disabled
  return if ENV['DISABLE_TELEMETRY'].to_s.downcase == 'true'
  # ...
end
```

### 12. Super Admin Views (Chat Support Removido)
**Caminhos:**
- `app/views/super_admin/application/_javascript.html.erb`
- `app/views/super_admin/settings/show.html.erb`

**Alteração:** Widget de Chat Support e botão removidos para privacidade

---

## Arquivos Criados

### Jobs
| Arquivo | Descrição |
|---------|-----------|
| `app/jobs/socialwise_debounce_job.rb` | Job para processar mensagens com debounce |

### Services - SocialWise Flow
| Arquivo | Descrição |
|---------|-----------|
| `lib/integrations/socialwise_flow/processor_service.rb` | Serviço principal do SocialWise Flow |
| `lib/integrations/socialwise_flow/debounce_processor_service.rb` | Serviço de processamento de debounce |
| `lib/integrations/socialwise_flow/whatsapp_response_processor.rb` | Processador de respostas WhatsApp |

### Services - SocialWise Core (Internos)
| Arquivo | Descrição |
|---------|-----------|
| `lib/integrations/socialwise/webhook_enhancer_service.rb` | Serviço interno que adiciona dados ao payload (wamid, contact_source, etc.) |
| `lib/integrations/socialwise/cache_manager.rb` | Gerenciador de cache interno |
| `lib/integrations/socialwise/instagram_response_processor.rb` | Processador de respostas Instagram |

> **Nota:** Estes services são usados internamente pelo ProcessorService e não são features configuráveis pelo usuário.

### Services - Messages
| Arquivo | Descrição |
|---------|-----------|
| `app/services/messages/instagram_renderer_mapper.rb` | Mapper para mensagens ricas do Instagram |
| `app/services/instagram/rich_message_service.rb` | Serviço de mensagens ricas do Instagram |

### Models
| Arquivo | Descrição |
|---------|-----------|
| `app/models/account_feature_flag.rb` | Modelo para feature flags por conta |
| `app/models/concerns/socialwise_cache_invalidation.rb` | Concern de invalidação de cache |

### Initializers
| Arquivo | Descrição |
|---------|-----------|
| `config/initializers/socialwise_cache.rb` | Inicializador de preload de cache |

### Assets
| Arquivo | Descrição |
|---------|-----------|
| `public/dashboard/images/integrations/socialwise-flow.png` | Logo do SocialWise Flow |
| `public/dashboard/images/integrations/socialwise-flow-dark.png` | Logo dark do SocialWise Flow |

### Docker
| Arquivo | Descrição |
|---------|-----------|
| `docker/entrypoints/rails-enterprise.sh` | Entrypoint para Docker Enterprise |

---

## Arquivos Removidos (DEFASADOS)

| Arquivo | Motivo |
|---------|--------|
| `app/controllers/api/v1/accounts/integrations/socialwise_chatwit_controller.rb` | Não necessário - hooks_controller gerencia integrações inbox |

---

## Migrações Necessárias

### Migration Copiada
| Arquivo | Descrição |
|---------|-----------|
| `db/migrate/20250101000001_create_account_feature_flags.rb` | Cria tabela de feature flags por conta |

### Executar Migration
```bash
bundle exec rails db:migrate
```

---

## Variáveis de Ambiente

| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `SOCIALWISE_DEBOUNCE_MS` | Tempo de debounce em milissegundos (apenas para texto, cliques de botão são sempre imediatos) | `0` (desabilitado) |
| `SOCIALWISE_DEBOUNCE_MAX_MS` | Timeout máximo do debounce em ms | `30000` |
| `SKIP_SOCIALWISE_CACHE` | Desabilita preload de cache | `false` |
| `DISABLE_TELEMETRY` | Desabilita telemetria e comunicação com hub | `false` |

> **Nota:** Cliques de botão e seleções de lista **NUNCA** passam por debounce, independente do valor de `SOCIALWISE_DEBOUNCE_MS`. Isso garante resposta imediata para ações deliberadas do usuário.

---

## Webhook Oficial

**URL do Webhook SocialWise Flow:**
```
https://socialwise.witdev.com.br/api/integrations/webhooks/socialwiseflow
```

---

## Comandos Pós-Instalação

```bash
# 1. Instalar dependências Ruby
bundle install

# 2. Instalar dependências Node
pnpm install

# 3. Executar migrações
bundle exec rails db:migrate

# 4. Rebuild Docker (se usando Docker)
./build-producao.sh

# 5. Reiniciar serviços
overmind restart
```

---

## Como Ativar a Integração

1. Acesse o painel do Chatwoot
2. Vá em **Settings > Integrations**
3. Encontre **SocialWise Flow**
4. Clique em **Connect**
5. **Selecione uma Caixa de Entrada** (inbox) para conectar
6. Configure as opções:
   - **Endpoint:** URL do webhook (ex: `https://socialwise.witdev.com.br/api/integrations/webhooks/socialwiseflow`)
   - **Access Token:** Token de autenticação (opcional)
   - **Idioma:** Código do idioma (ex: pt-BR)

---

## Logs Esperados (Quando Funcionando Corretamente)

Quando o SocialWise Flow está funcionando corretamente, você deve ver os seguintes logs no console/arquivo de log:

```log
# 1. Mensagem recebida e evento disparado
I, INFO -- : [HOOK_LISTENER] === execute_hooks called ===
I, INFO -- : [HOOK_LISTENER] Event: message.created
I, INFO -- : [HOOK_LISTENER] Message ID: 12345
I, INFO -- : [HOOK_LISTENER] DISPATCHING: HookJob for hook 1 (socialwise_flow)

# 2. Job processando
I, INFO -- : [HOOK_JOB] === HookJob.perform called ===
I, INFO -- : [HOOK_JOB] Hook ID: 1, App ID: socialwise_flow
I, INFO -- : [HOOK_JOB] Event type is valid, calling ProcessorService

# 3. ProcessorService validando
I, INFO -- : [SOCIALWISE-FLOW] === ProcessorService.perform called ===
I, INFO -- : [SOCIALWISE-FLOW] === CHECKING SHOULD_RUN_PROCESSOR ===
I, INFO -- : [SOCIALWISE-FLOW] Conversation status: open  # ou pending
I, INFO -- : [SOCIALWISE-FLOW] Checking bot_should_respond: status=open, has_agent_reply=false
I, INFO -- : [SOCIALWISE-FLOW] PASSED: All checks passed, will process message

# 4. Enviando para webhook
I, INFO -- : [SOCIALWISE-FLOW] === SENDING REQUEST TO SOCIALWISE FLOW ===
I, INFO -- : [SOCIALWISE-FLOW] URL: https://socialwise.witdev.com.br/api/integrations/webhooks/socialwiseflow
I, INFO -- : [SOCIALWISE-FLOW] PAYLOAD: {session_id: "558597550136", message: "Olá!"}

# 5. Resposta recebida
I, INFO -- : [SOCIALWISE-FLOW] Response received: {"whatsapp" => {"type" => "interactive", ...}}

# 6. Processando resposta
I, INFO -- : [SOCIALWISE-FLOW] === PROCESSING RESPONSE ===
I, INFO -- : [SOCIALWISE-FLOW-WHATSAPP] Interactive message created: 47328
```

---

## Fluxo de Funcionamento

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Mensagem       │────▶│  Hook Listener   │────▶│  Hook Job       │
│  Recebida       │     │  (message.created)│     │                 │
└─────────────────┘     └──────────────────┘     └────────┬────────┘
                                                         │
                                                         ▼
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Webhook        │◀────│  Processor       │◀────│  Debounce       │
│  SocialWise     │     │  Service         │     │  (se habilitado)│
└─────────────────┘     └──────────────────┘     └─────────────────┘
                                                         │
                                                         ▼
                       ┌──────────────────┐     ┌─────────────────┐
                       │  Mensagem        │◀────│  Response       │
                       │  de Resposta     │     │  Processor      │
                       └──────────────────┘     └─────────────────┘
```

---

## Estrutura de Diretórios

```
lib/integrations/
├── socialwise/
│   ├── cache_manager.rb
│   ├── instagram_response_processor.rb
│   └── webhook_enhancer_service.rb
└── socialwise_flow/
    ├── debounce_processor_service.rb
    ├── processor_service.rb
    └── whatsapp_response_processor.rb

app/
├── jobs/
│   └── socialwise_debounce_job.rb
├── models/
│   ├── account_feature_flag.rb
│   └── concerns/
│       └── socialwise_cache_invalidation.rb
└── services/
    ├── instagram/
    │   └── rich_message_service.rb
    └── messages/
        └── instagram_renderer_mapper.rb
```

---

## Troubleshooting - Webhook não está sendo enviado

### Quando o Bot Responde (Lógica Atualizada 2026-02-01)

O SocialWise Flow processa mensagens quando:
1. **Conversa `pending`** - Nenhum agente atribuído ainda
2. **Conversa `open` SEM resposta de agente** - Auto-atribuída mas nenhum humano respondeu

O webhook **NÃO** é disparado quando:
- A conversa está `resolved` ou `snoozed`
- A conversa está `open` E já tem resposta de um agente humano

**Motivo:** Evitar que o bot interfira quando um agente humano já está atendendo.

### Logs de Diagnóstico Adicionados (2026-02-01)

Foram adicionados logs extensivos para ajudar a identificar problemas. Verifique os logs do Rails para:

```log
# 1. HookListener - Verifica se o evento está sendo capturado
[HOOK_LISTENER] === execute_hooks called ===
[HOOK_LISTENER] Event: message.created
[HOOK_LISTENER] Total hooks in account: X
[HOOK_LISTENER] Checking hook ID: X, app_id: socialwise_flow, inbox_id: X, disabled: false

# 2. HookJob - Verifica se o job está sendo executado
[HOOK_JOB] === HookJob.perform called ===
[HOOK_JOB] Hook ID: X, App ID: socialwise_flow
[HOOK_JOB] Processing hook app_id: socialwise_flow

# 3. ProcessorService - Verifica se a mensagem está sendo processada
[SOCIALWISE-FLOW] === ProcessorService.perform called ===
[SOCIALWISE-FLOW] === CHECKING SHOULD_RUN_PROCESSOR ===
[SOCIALWISE-FLOW] Message ID: X
[SOCIALWISE-FLOW] Message private?: false
[SOCIALWISE-FLOW] Conversation status: open  # ou pending
[SOCIALWISE-FLOW] Checking bot_should_respond: status=open, has_agent_reply=false

# 4. Se bloqueado (agente já respondeu), verá:
[SOCIALWISE-FLOW] BLOCKED: Bot should not respond (status: open, has_agent_reply: true)
```

### Checklist de Troubleshooting

1. **Verificar status da conversa:**
   ```sql
   SELECT id, status FROM conversations WHERE id = X;
   -- Status deve ser 'pending' para o webhook funcionar
   ```

2. **Verificar se o hook está configurado corretamente:**
   ```sql
   SELECT * FROM hooks WHERE app_id = 'socialwise_flow';
   -- Verificar: hook_type, inbox_id, status
   ```

3. **Verificar se o hook NÃO está desabilitado:**
   ```sql
   SELECT id, status FROM hooks WHERE app_id = 'socialwise_flow';
   -- status deve ser diferente de 'disabled'
   ```

4. **Verificar se a inbox do hook corresponde à inbox da mensagem:**
   ```sql
   SELECT h.id, h.inbox_id, i.name
   FROM hooks h
   JOIN inboxes i ON h.inbox_id = i.id
   WHERE h.app_id = 'socialwise_flow';
   ```

5. **Verificar logs do Rails:**
   ```bash
   tail -f log/development.log | grep -E "(HOOK_LISTENER|HOOK_JOB|SOCIALWISE-FLOW)"
   ```

---

## Problemas Conhecidos e Soluções

### 1. Webhook não é enviado (CORRIGIDO em 2026-02-01)
**Problema Original:** A conversa era criada com status `open` (auto-atribuição) em vez de `pending`, bloqueando o webhook.

**Solução Implementada (2 partes):**

**Parte 1 - ProcessorService:** Aceita conversas `pending` OU `open` sem resposta de agente:
```ruby
def bot_should_respond?
  return true if conversation.pending?
  return true if conversation.open? && !has_agent_reply?
  false
end
```

**Parte 2 - DebounceProcessorService:** Mesma correção aplicada ao processador de debounce:
- O `debounce_processor_service.rb` também usava `conversation.pending?` como condição
- Corrigido para usar `bot_should_respond?` herdado da classe pai
- **CRÍTICO:** Sem esta correção, o debounce funcionava mas o webhook NUNCA era enviado

**Sintoma:** Logs mostravam "Processing completed for conversation X" mas sem o log "=== SENDING REQUEST TO SOCIALWISE FLOW ==="

Isso permite que o bot responda a novas conversas mesmo com auto-atribuição, mas **não responda** quando um agente já está atendendo.

### 2. Integração mostra campos errados (Access Key, Secret Key)
**Causa:** `hook_type: account` em vez de `hook_type: inbox`
**Solução:** Usar `socialwise_flow` com `hook_type: inbox` em apps.yml

### 3. Cache não atualiza após editar inbox
**Solução:** O concern `SocialwiseCacheInvalidation` foi adicionado ao modelo Inbox para limpar o cache automaticamente.

### 4. HTTParty não encontrado
**Solução:** Execute `bundle install` para instalar a gem.

### 5. Migration falha
**Solução:** Verifique se a versão do Rails é compatível (7.0+) e execute `bundle exec rails db:migrate:status` para verificar o status.

### 6. Docker container não inicia (rails-enterprise.sh not found)
**Solução:** Copiar `docker/entrypoints/rails-enterprise.sh` do fork original.

### 7. Hook não aparece na lista de integrações
**Causa:** Arquivo `apps.yml` não foi atualizado ou contém erro de sintaxe
**Solução:** Verifique o arquivo `config/integration/apps.yml` e reinicie o servidor

### 8. NoMethodError: undefined method 'send_interactive_payload' (CORRIGIDO em 2026-02-02)
**Causa:** O Chatwoot v4.10 não possui o método `send_interactive_payload` no `WhatsappCloudService`
**Sintoma:** O fluxo funciona até receber a resposta do webhook, mas falha ao enviar botões/listas interativos

**Solução Implementada:** Portado o método `send_interactive_payload` do fork v4.4 para o v4.10:
```ruby
# app/services/whatsapp/providers/whatsapp_cloud_service.rb
def send_interactive_payload(phone_number, message, interactive_payload)
  @message = message
  response = HTTParty.post(
    "#{phone_id_path}/messages",
    headers: api_headers,
    body: {
      messaging_product: 'whatsapp',
      to: phone_number,
      interactive: interactive_payload,
      type: 'interactive'
    }.to_json
  )
  process_response(response, message)
end
```

### 9. Mensagens duplicadas (uma com botões, outra sem) (CORRIGIDO em 2026-02-02)
**Causa:** O Chatwoot v4.10 não possui o mecanismo `skip_send_reply` para evitar envio duplo
**Sintoma:** Mensagem interativa é enviada 2 vezes - uma correta (com botões) e outra errada (só texto)

**Fluxo do problema:**
1. `WhatsappResponseProcessor` cria mensagem com `additional_attributes: { skip_send_reply: true }`
2. Callback `after_create_commit` enfileira `SendReplyJob` automaticamente (ignora a flag!)
3. `WhatsappResponseProcessor` envia manualmente via `send_interactive_payload` (mensagem 1)
4. `SendReplyJob` processa e envia via `SendOnWhatsappService` (mensagem 2 - duplicada)

**Solução Implementada:** Adicionada verificação no modelo `Message`:
```ruby
# app/models/message.rb
def send_reply
  # Skip sending reply if message is marked to skip
  return if additional_attributes&.dig('skip_send_reply')

  # ... resto do código
end
```

### 10. Bot continua respondendo após handoff (CORRIGIDO em 2026-02-02)
**Causa:** Após handoff, a conversa ficava com status `open` e nenhum agente humano havia respondido ainda
**Sintoma:** Mesmo após executar handoff (transferência para humano), o bot continuava enviando mensagens ao SocialWise

**Contexto do problema:**
- Dialogflow nativo usa `conversation.pending?` como verificação
- No Chatwit 4.10 com auto-atribuição, conversas começam como `open`
- A correção anterior aceitava `open` sem resposta humana para permitir o bot funcionar
- Mas isso criou um problema: handoff muda status para `open` (que já era `open`), sem forma de detectar que handoff ocorreu

**Solução Implementada:**
1. Marcar handoff em `additional_attributes['socialwise_handoff_at']`
2. Verificar esta flag antes de permitir resposta do bot
3. Limpar a flag quando conversa é resolvida (permite bot funcionar se reaberta)

```ruby
# Verificação atualizada em processor_service.rb
def bot_should_respond?
  return true if conversation.pending?
  return true if conversation.open? && !has_agent_reply? && !handoff_completed?
  false
end

def handoff_completed?
  conversation.additional_attributes&.dig('socialwise_handoff_at').present?
end
```

**Vantagens da solução:**
- Não afeta métricas de SLA (usa `additional_attributes`, não `first_reply_created_at`)
- Flag é limpa quando conversa é resolvida, permitindo bot funcionar novamente se reaberta meses depois
- Compatível com auto-atribuição de conversas

---

## Histórico de Alterações

### 2026-02-02 (Atualização 6) - Melhoria: Cliques de botão sem debounce
- **ADICIONADO:** Método `interactive_reply?` no `processor_service.rb`
- **FUNCIONALIDADE:** Cliques de botão e seleções de lista são processados imediatamente, sem debounce
- **MOTIVO:** Cliques de botão são ações deliberadas que esperam resposta imediata

**Por que essa melhoria?**
1. Cliques de botão são ações intencionais do usuário
2. Não faz sentido esperar mais mensagens após um clique
3. O contexto da interação (button_id) precisa ser enviado imediatamente
4. Melhora a experiência do usuário com resposta mais rápida

**Implementação:**
```ruby
# lib/integrations/socialwise_flow/processor_service.rb

def perform
  # ... validações ...

  # Cliques de botão SEMPRE processados imediatamente
  if interactive_reply?(message)
    Rails.logger.info '[SOCIALWISE-FLOW] Interactive reply detected - processing immediately'
    process_content(message)
    return
  end

  # Debounce apenas para mensagens de texto normais
  if debounce_ms.positive?
    enqueue_for_debounce(message, debounce_ms)
  else
    process_content(message)
  end
end

def interactive_reply?(message)
  content_attrs = message.content_attributes
  return false if content_attrs.blank?

  has_button_reply = content_attrs['button_reply'].present?
  has_list_reply = content_attrs['list_reply'].present?

  has_button_reply || has_list_reply
end
```

**Comportamento:**
| Tipo de mensagem | Debounce aplicado? |
|------------------|-------------------|
| Texto normal | ✅ Sim (se configurado) |
| Clique de botão | ❌ Não (imediato) |
| Seleção de lista | ❌ Não (imediato) |
| Áudio/Imagem/Vídeo | ✅ Sim (se configurado) |

### 2026-02-02 (Atualização 5) - Correção: Bot continua respondendo após Handoff
- **ADICIONADO:** Método `process_action` no `processor_service.rb` (override do método herdado)
- **ADICIONADO:** Métodos `mark_handoff_completed`, `clear_handoff_flag`, `handoff_completed?`
- **ATUALIZADO:** `bot_should_respond?` agora verifica se handoff foi executado
- **FUNCIONALIDADE:** Bot para de responder após handoff, mesmo que nenhum humano tenha respondido ainda
- **FUNCIONALIDADE:** Flag é limpa quando conversa é resolvida, permitindo bot funcionar se reaberta no futuro

**Problema identificado:**
1. Conversa com auto-atribuição inicia com status `open`
2. Bot responde porque `bot_should_respond?` retornava `true` para `open` sem resposta de agente
3. Mesmo após handoff, bot continuava respondendo porque:
   - Handoff apenas muda status para `open` (já estava `open`)
   - Não havia forma de saber que handoff ocorreu

**Solução Implementada:**
```ruby
# lib/integrations/socialwise_flow/processor_service.rb

# Verificação atualizada
def bot_should_respond?
  return true if conversation.pending?
  return true if conversation.open? && !has_agent_reply? && !handoff_completed?
  false
end

# Nova verificação
def handoff_completed?
  conversation.additional_attributes&.dig('socialwise_handoff_at').present?
end

# Override de process_action para marcar handoff
def process_action(message, action)
  case action
  when 'handoff'
    mark_handoff_completed(message.conversation)
    message.conversation.bot_handoff!
  when 'resolve'
    clear_handoff_flag(message.conversation)  # Permite bot funcionar se reaberta
    message.conversation.resolved!
  end
end

# Marca handoff em additional_attributes (não afeta métricas de SLA)
def mark_handoff_completed(conv)
  current_attrs = conv.additional_attributes || {}
  updated_attrs = current_attrs.merge(
    'socialwise_handoff_at' => Time.current.iso8601,
    'socialwise_handoff_by' => 'bot'
  )
  conv.update!(additional_attributes: updated_attrs)
end
```

**Comportamento após correção:**
| Situação | Bot responde? |
|----------|---------------|
| Conversa `pending` | ✅ Sim |
| Conversa `open` sem resposta humana, sem handoff | ✅ Sim |
| Conversa `open` após handoff | ❌ Não |
| Conversa `open` com resposta humana | ❌ Não |
| Conversa `resolved` | ❌ Não |
| Conversa reaberta após resolução | ✅ Sim (flag limpa) |

### 2026-02-02 (Atualização 4) - Correção: Button ID não enviado ao SocialWise
- **ADICIONADO:** Método `extract_interactive_data` no `incoming_message_base_service.rb`
- **CORRIGIDO:** `create_message` agora passa `content_attributes` com dados interativos
- **FUNCIONALIDADE:** Captura e armazena `button_reply.id` e `list_reply.id` em `content_attributes` para uso pelo SocialWise Flow
- **SINTOMA CORRIGIDO:** Clique de botão chegava ao webhook apenas com o título ("Atendimento Humano") mas sem o ID ("@falar_atendente")

**Fluxo do problema:**
1. WhatsApp envia webhook com `interactive.button_reply.id = "@falar_atendente"`
2. Chatwoot criava mensagem com apenas `content = "Atendimento Humano"` (ID era ignorado!)
3. SocialWise recebia payload sem o button_id
4. Bot não conseguia identificar qual botão foi clicado

**Solução Implementada:**
```ruby
# app/services/whatsapp/incoming_message_base_service.rb
def extract_interactive_data(message)
  return {} unless message[:type] == 'interactive'

  interactive_data = {}

  # Extract button reply data
  if message.dig(:interactive, :button_reply)
    button_reply = message[:interactive][:button_reply]
    interactive_data[:button_reply] = {
      id: button_reply[:id],
      title: button_reply[:title]
    }
    interactive_data[:interaction_type] = 'button_reply'
  end

  # Extract list reply data
  if message.dig(:interactive, :list_reply)
    list_reply = message[:interactive][:list_reply]
    interactive_data[:list_reply] = {
      id: list_reply[:id],
      title: list_reply[:title],
      description: list_reply[:description]
    }
    interactive_data[:interaction_type] = 'list_reply'
  end

  interactive_data
end
```

**Payload SocialWise agora inclui:**
```json
{
  "button_id": "@falar_atendente",
  "button_title": "Atendimento Humano",
  "interaction_type": "button_reply"
}
```

### 2026-02-02 (Atualização 3) - Suporte Instagram/Facebook Messenger
- **MIGRADO:** `Facebook::RichMessageService` do fork v4.4 → `app/services/facebook/rich_message_service.rb`
- **MIGRADO:** `InstagramChannelValidator` do fork v4.4 → `app/validators/instagram_channel_validator.rb`
- **MIGRADO:** `FacebookChannelValidator` do fork v4.4 → `app/validators/facebook_channel_validator.rb`
- **FUNCIONALIDADE:** Permite envio de mensagens ricas (carrosséis, botões, quick replies) no Instagram e Facebook Messenger
- **NOTA:** O `InstagramResponseProcessor` já existia no v4.10 e agora está completo com todas as dependências

**Arquivos criados:**
```
app/services/facebook/rich_message_service.rb    # Envia templates e quick replies no Facebook
app/validators/instagram_channel_validator.rb   # Valida canal Instagram antes de enviar
app/validators/facebook_channel_validator.rb    # Valida canal Facebook antes de enviar
```

**Canais suportados para mensagens ricas:**
| Canal | Processador | Serviço de Envio |
|-------|-------------|------------------|
| WhatsApp | `WhatsappResponseProcessor` | `WhatsappCloudService.send_interactive_payload` |
| Instagram | `InstagramResponseProcessor` | `Instagram::RichMessageService` |
| Facebook | `InstagramResponseProcessor` | `Facebook::RichMessageService` |

### 2026-02-02 (Atualização 2) - Correção: Mensagens Duplicadas
- **ADICIONADO:** Verificação `skip_send_reply` no modelo `Message` (app/models/message.rb)
- **PORTADO:** Mecanismo do fork v4.4 para evitar envio duplo de mensagens
- **FUNCIONALIDADE:** Quando `additional_attributes['skip_send_reply']` é `true`, o callback automático `SendReplyJob` não é enfileirado
- **SINTOMA CORRIGIDO:** Mensagem interativa era enviada 2x (uma com botões, outra só texto)

**Código adicionado:**
```ruby
def send_reply
  # Skip sending reply if message is marked to skip
  return if additional_attributes&.dig('skip_send_reply')
  # ... resto do código
end
```

### 2026-02-02 - Correção: Método send_interactive_payload
- **ADICIONADO:** Método `send_interactive_payload` no `whatsapp_cloud_service.rb`
- **PORTADO:** Código do fork v4.4 adaptado para estrutura do v4.10
- **FUNCIONALIDADE:** Permite envio de mensagens interativas (botões/listas) geradas por bots externos
- **SINTOMA CORRIGIDO:** `NoMethodError: undefined method 'send_interactive_payload'`

### 2026-02-01 (Atualização 2) - Correção do DebounceProcessorService
- **CORRIGIDO:** `debounce_processor_service.rb` também usava verificação `conversation.pending?` que bloqueava silenciosamente
- **CORRIGIDO:** Agora usa `bot_should_respond?` herdado da classe pai ProcessorService
- **ADICIONADO:** Logs extensivos de diagnóstico no DebounceProcessorService
- **SINTOMA:** Job de debounce completava ("Processing completed") mas webhook nunca era enviado (job terminava em ~9ms)

### 2026-02-01 - Correção Crítica: Webhook para Conversas Auto-Atribuídas
- **CORRIGIDO:** `processor_service.rb` agora aceita conversas `open` sem resposta de agente
- **ADICIONADO:** Métodos `bot_should_respond?` e `has_agent_reply?` para lógica inteligente
- **ADICIONADO:** Logs extensivos de diagnóstico em `hook_listener.rb`, `hook_job.rb` e `processor_service.rb`
- **DOCUMENTADO:** Checklist de troubleshooting para problemas de webhook

**Problema Resolvido:** Conversas com auto-atribuição eram criadas com status `open`, bloqueando o webhook. Agora o bot responde a conversas `open` que ainda não tiveram resposta de agente humano.

### 2026-01-31 - Correção Crítica
- **CORRIGIDO:** Substituído `socialwise_chatwit` por `socialwise_flow` com `hook_type: inbox`
- **REMOVIDO:** Controller `socialwise_chatwit_controller.rb` (desnecessário)
- **ADICIONADO:** Traduções pt_BR para SocialWise Flow
- **ADICIONADO:** Bloqueio de telemetria em `chatwoot_hub.rb`
- **REMOVIDO:** Widget de Chat Support no super_admin
- **COPIADO:** `rails-enterprise.sh` para Docker Enterprise

### 2026-01-30 - Implementação Inicial
- Integração SocialWise Flow com debounce
- Services de processamento de webhook
- Suporte a mensagens ricas (WhatsApp, Instagram, Facebook)

---

## Próximos Passos (Etapa 2)

1. **Stickers**
   - Adicionar rotas de stickers
   - Configurar frontend
   - Implementar upload e envio

2. **UI/UX**
   - Melhorar interface de configuração
   - Adicionar logs visuais
   - Dashboard de métricas

---

## Contato

Para dúvidas ou problemas, abra uma issue no repositório ou entre em contato com a equipe de desenvolvimento.
