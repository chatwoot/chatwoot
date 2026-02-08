# Technology Stack

## 📦 Stack Tecnológico

### Backend
- **Ruby 3.4.4** + **Rails 7.1.x**
- **PostgreSQL** com pgvector (AI/ML)
- **Redis** (cache + background jobs)
- **Sidekiq** + sidekiq-cron
- **Devise** (auth) + **JWT** + **Pundit** (autorização)
- **Active Storage** com S3/Azure/GCS

### Frontend
- **Node.js 23.x** + **pnpm 10.x**
- **Vite 5.x** + vite-plugin-ruby
- **Vue.js 3.x** + Vuex
- **Tailwind CSS 3.x**
- **Vitest** (testes)

### DevOps
- **Docker** + docker-compose
- **Foreman** (desenvolvimento local)
- **RuboCop** + **ESLint**

## 🛠️ Comandos Essenciais

```bash
# Setup inicial
bundle install && pnpm install
rails db:create db:migrate db:seed

# Desenvolvimento
foreman start -f Procfile.dev
# OU Docker
./build-desenvolvimento.ps1
docker-compose up

# Testes
docker exec chatwit-dev-rails-1 bundle exec rspec
pnpm test

# Linting
docker exec chatwit-dev-rails-1 bundle exec rubocop -a
pnpm eslint:fix
```

## 🔴 SOLUÇÕES CRÍTICAS IMPLEMENTADAS

### 1. ⚠️ Conversation ID vs Display ID

**ERRO FATAL**: Controllers devem usar `display_id`, não `id` interno!

```ruby
# ❌ NUNCA FAÇA
conversation = current_account.conversations.find(params[:conversation_id])

# ✅ SEMPRE USE
conversation = current_account.conversations.find_by!(display_id: params[:conversation_id])
```

**Por quê?** URLs contêm `display_id` público. Usar `find(id)` retorna conversa errada!

### 2. 🔄 Evitando Envio Duplo de Mensagens

**Problema**: Mensagens enviadas 2x (dashboard + API)

**Solução**: Flag `skip_send_reply`

```ruby
# Ao criar mensagem que será enviada por serviço customizado
message = conversation.messages.create!(
  content: content,
  message_type: :outgoing,
  additional_attributes: { skip_send_reply: true } # CRÍTICO!
)

# Model verifica a flag
def send_reply
  return if additional_attributes&.dig('skip_send_reply')
  # ... envio normal
end
```

### 3. 📋 MessageBuilder Obrigatório

**REGRA**: SEMPRE use `Messages::MessageBuilder` para criar mensagens

```ruby
# ❌ ERRADO - Criação direta
message = @conversation.messages.create!(content: content)

# ✅ CORRETO - MessageBuilder
message_params = ActionController::Parameters.new({
  content: content,
  content_type: content_type,
  content_attributes: content_attributes,
  message_type: 'outgoing',
  additional_attributes: { skip_send_reply: true }
})

builder = Messages::MessageBuilder.new(@user, @conversation, message_params)
message = builder.perform

# Atualizar source_id para status checks
message.update!(source_id: response[:message_id]) if response[:message_id]
```

### 4. 🗄️ Cache com Redis::Alfred (NÃO Rails.cache)

```ruby
# ❌ EVITAR
Rails.cache.fetch(cache_key) { expensive_operation }

# ✅ PADRÃO CHATWOOT
cached_value = Redis::Alfred.get(cache_key)
if cached_value.nil?
  value = expensive_operation
  Redis::Alfred.setex(cache_key, value, 30.days)
  value
else
  cached_value
end

# Chaves padronizadas em lib/redis/redis_keys.rb
cache_key = format(Redis::RedisKeys::WHATSAPP_MEDIA_CACHE,
                   channel_id: @channel.id,
                   url_hash: url_hash)
```

### 5. 🔄 Snake_case ↔ camelCase

**Backend (Ruby)**: snake_case  
**Frontend (Vue)**: camelCase (transformação automática)

```javascript
// ❌ ERRADO - Frontend procurando snake_case
const data = contentAttributes.value?.custom_data

// ✅ CORRETO - Frontend usa camelCase
const data = contentAttributes.value?.customData
```

### 6. 🎯 N+1 Queries com Active Storage

```ruby
# ❌ N+1 queries
query.includes(:file_attachment)

# ✅ Otimizado
query.includes(file_attachment: :blob)
```

### 7. 🔧 Encoding Binário

```ruby
# Dados binários de APIs externas
media_data = response.body.force_encoding('BINARY')
temp_file.binmode
temp_file.write(media_data)
```

## 🔗 URLs Públicas para Active Storage

**ERRO CRÍTICO**: URLs internas `/disk/` não funcionam para serviços externos!

```ruby
# ❌ ERRADO - URL interna, não funciona para WhatsApp/Telegram
def download_url
  file.blob.url # Gera /disk/... - NÃO ACESSÍVEL EXTERNAMENTE!
end

# ✅ CORRETO - URL pública
def download_url
  if file.attached?
    Rails.application.routes.url_helpers.rails_blob_url(file.blob, only_path: false)
  else
    ''
  end
end

# Alternativas por contexto:
rails_blob_url(file.blob, only_path: false)  # APIs externas
rails_blob_path(file.blob, disposition: "attachment")  # Downloads
rails_blob_path(file.blob, disposition: "inline")  # Exibição
```

## 🏗️ PADRÕES ARQUITETURAIS

### Service Objects com Error Handling Robusto

```ruby
class BaseService
  # Classes de erro customizadas para melhor controle
  class ServiceError < StandardError; end
  class ValidationError < ServiceError; end
  class ExternalApiError < ServiceError; end
  class RateLimitError < ServiceError; end

  def perform
    Rails.logger.info "#{self.class.name}: Starting operation"
    
    validate_inputs!
    result = execute_operation
    
    Rails.logger.info "#{self.class.name}: Completed successfully"
    { success: true, data: result }
    
  rescue ValidationError => e
    Rails.logger.error "#{self.class.name}: Validation failed: #{e.message}"
    { success: false, error: e.message, type: 'validation' }
    
  rescue ExternalApiError => e
    Rails.logger.error "#{self.class.name}: External API error: #{e.message}"
    { success: false, error: e.message, type: 'external_api', retry_after: 60 }
    
  rescue RateLimitError => e
    Rails.logger.warn "#{self.class.name}: Rate limit hit: #{e.message}"
    { success: false, error: 'Too many requests', type: 'rate_limit', retry_after: e.retry_after }
    
  rescue StandardError => e
    Rails.logger.error "#{self.class.name}: Unexpected error: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    Sentry.capture_exception(e) if defined?(Sentry)
    { success: false, error: 'Internal server error', type: 'internal' }
  end

  private

  def validate_inputs!
    raise ValidationError, 'Invalid input' unless valid_input?
  end

  def execute_operation
    # Implementação específica
  end
end
```

### Retry Pattern para APIs Externas

```ruby
def with_retry(max_attempts: 3, delay: 1, backoff: true)
  attempts = 0
  
  begin
    attempts += 1
    yield
    
  rescue ExternalApiError => e
    if attempts < max_attempts
      wait_time = backoff ? delay * attempts : delay
      Rails.logger.warn "Attempt #{attempts} failed: #{e.message}. Retrying in #{wait_time}s..."
      sleep(wait_time)
      retry
    else
      Rails.logger.error "All #{max_attempts} attempts failed: #{e.message}"
      raise
    end
  end
end

# Uso
def send_to_external_api(data)
  with_retry(max_attempts: 3, delay: 2, backoff: true) do
    response = HTTParty.post(api_url, body: data.to_json, headers: headers)
    
    case response.code
    when 429  # Rate limit
      raise RateLimitError.new("Rate limited", retry_after: response.headers['Retry-After'])
    when 500..599  # Server error
      raise ExternalApiError, "Server error: #{response.code}"
    when 200..299  # Success
      response.parsed_response
    else
      raise ValidationError, "Unexpected response: #{response.code}"
    end
  end
end
```

### Estrutura de Diretórios

```
app/services/
├── conversations/
├── messages/
├── integrations/
└── [channel_name]/

app/javascript/dashboard/components-next/message/
├── bubbles/
│   ├── Base.vue
│   └── [CustomType].vue
└── constants.js
```

### Componentes Vue para Mensagens

```vue
<script setup>
import { computed } from 'vue';
import BaseBubble from './Base.vue';
import { useMessageContext } from '../provider.js';

const { contentAttributes } = useMessageContext();

// SEMPRE camelCase no frontend!
const customData = computed(() => {
  return contentAttributes.value?.customData || {};
});
</script>

<template>
  <BaseBubble>
    <!-- Conteúdo -->
  </BaseBubble>
</template>
```

## 🗃️ Migrações PostgreSQL JSONB

```ruby
# ✅ PADRÃO SEGURO
def up
  execute <<-SQL
    CREATE INDEX IF NOT EXISTS index_name
    ON table_name (field1, field2, (meta->>'json_key'))
    WHERE meta->>'json_key' IS NOT NULL;
  SQL
end

# ❌ EVITAR
add_index :table, [:field, "(meta->>'key')"] # Falha sem dados
execute "CREATE INDEX CONCURRENTLY ..." # Falha em transação
```

## 🔒 SEGURANÇA E VALIDAÇÃO DE DADOS

### Strong Parameters (Obrigatório em Controllers)

```ruby
# ❌ INSEGURO - Permite mass assignment
def create
  message = Message.create(params[:message])
end

# ✅ SEGURO - Strong parameters
def create
  message = Message.create(message_params)
end

private

def message_params
  params.require(:message).permit(
    :content, :content_type, :message_type,
    content_attributes: {},  # Permite hash aninhado
    additional_attributes: [:skip_send_reply, :custom_field]  # Campos específicos
  )
end
```

### Validações e Sanitização no Model

```ruby
class Message < ApplicationRecord
  # Validações críticas
  validates :content, presence: true, length: { maximum: 10000 }
  validates :message_type, inclusion: { in: %w[incoming outgoing] }
  validates :account_id, presence: true
  validate :validate_content_attributes_structure

  # Sanitização automática contra XSS
  before_save :sanitize_content

  private

  def sanitize_content
    if content_changed? && content_type == 'text'
      self.content = ActionController::Base.helpers.sanitize(
        content,
        tags: %w[b i u a br p],  # Tags permitidas
        attributes: %w[href target]  # Atributos permitidos
      )
    end
  end

  def validate_content_attributes_structure
    if content_attributes.present?
      # Validar estrutura JSON esperada
      errors.add(:content_attributes, 'invalid structure') unless valid_json_structure?
    end
  end
end
```

### Rate Limiting com Rack::Attack

```ruby
# config/initializers/rack_attack.rb

# Limitar APIs públicas
Rack::Attack.throttle('api/requests_per_ip', limit: 100, period: 1.hour) do |req|
  req.ip if req.path.start_with?('/api/')
end

# Limitar tentativas de login
Rack::Attack.throttle('login/email', limit: 5, period: 20.seconds) do |req|
  if req.path == '/users/sign_in' && req.post?
    req.params['user']['email'].presence
  end
end

# Bloquear IPs abusivos
Rack::Attack.blocklist('block_suspicious_ips') do |req|
  # Lista de IPs suspeitos do Redis
  Redis::Alfred.sismember('blocked_ips', req.ip)
end

# Resposta customizada para rate limit
Rack::Attack.throttled_response = lambda do |env|
  [429, 
   { 'Content-Type' => 'application/json' },
   [{ error: 'Too many requests', retry_after: 60 }.to_json]]
end
```

## 🚀 OTIMIZAÇÕES AVANÇADAS DE PERFORMANCE

```ruby
Rails.logger.info "#{self.class.name}: Starting operation for #{resource} #{id}"
Rails.logger.info "  - Key detail: #{value}"

# API logs
Rails.logger.info "API Request: #{method} #{url}"
Rails.logger.info "  - Headers: #{headers.except('Authorization')}"
Rails.logger.info "API Response: #{response.code} (#{duration}ms)"
```

## 🎯 Checklist de Conformidade

### Backend
- [ ] Usar `Messages::MessageBuilder` para mensagens
- [ ] `ActionController::Parameters.new()` para parâmetros
- [ ] `additional_attributes: { skip_send_reply: true }` quando necessário
- [ ] Atualizar `source_id` após envio
- [ ] `Redis::Alfred` para cache
- [ ] Service objects com error handling robusto
- [ ] Logs estruturados

### Segurança
- [ ] **Strong parameters em TODOS os controllers**
- [ ] **Validações robustas nos models**
- [ ] **Sanitização de conteúdo contra XSS**
- [ ] **Rate limiting configurado**
- [ ] **URLs públicas com rails_blob_url para APIs externas**
- [ ] **Classes de erro customizadas em services**

### Frontend
- [ ] `useMessageContext()` para dados
- [ ] Acessar dados em **camelCase**
- [ ] Estender `BaseBubble` para novos tipos
- [ ] Tratar loading/erro

### Performance
- [ ] Evitar N+1 com eager loading completo
- [ ] **Paginação por cursor para grandes datasets**
- [ ] **Bulk operations (insert_all/update_all)**
- [ ] **Cache de queries complexas com Redis::Alfred**
- [ ] Índices JSONB apropriados
- [ ] Processar em batches (find_in_batches)

## 🔑 Lições Aprendidas Críticas

1. **SEMPRE use display_id em controllers de conversation**
2. **NUNCA crie mensagens sem MessageBuilder**
3. **USE Redis::Alfred, não Rails.cache**
4. **Frontend = camelCase, Backend = snake_case**
5. **skip_send_reply previne duplicação**
6. **source_id habilita status checks**
7. **rails_blob_url para URLs externas (WhatsApp/Telegram)**
8. **Strong parameters em TODOS os controllers**
9. **Sanitizar conteúdo contra XSS**
10. **Error handling com classes customizadas**
11. **Paginação por cursor > offset pagination**
12. **insert_all/update_all para operações em massa**
13. **Rate limiting obrigatório em APIs públicas**
14. **Includes(:blob) evita N+1 queries**
15. **force_encoding('BINARY') para dados binários**


## 🔄 Fluxo de Integração Padrão

1. **Receber webhook** → WhatsappResponseProcessor
2. **Processar mensagem** → MessageProcessorService  
3. **Criar no dashboard** → Messages::MessageBuilder
4. **Enviar resposta** → skip_send_reply: true
5. **Atualizar status** → source_id = message_id
6. **Cache media** → Redis::Alfred

---

**💡 Dica Final**: Este documento é a fonte da verdade. Quando em dúvida, siga estes padrões para garantir compatibilidade total com a arquitetura nativa do Chatwoot!