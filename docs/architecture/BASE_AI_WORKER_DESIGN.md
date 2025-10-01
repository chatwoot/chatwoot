# BaseAiWorker Design Document

**Author**: Simón (AI Worker Architect)
**Date**: 2025-09-30
**Version**: 1.0
**Purpose**: Define the architecture, interfaces, and implementation patterns for the GP Bikes AI Worker system

---

## Executive Summary

**BaseAiWorker** is an abstract base class that provides the foundation for all AI-powered message processors in GP Bikes. It implements the **Chain of Responsibility** pattern, allowing multiple workers to evaluate and process messages sequentially until one worker handles the message successfully.

### Key Design Principles

1. **Open/Closed Principle**: Workers are open for extension (create new workers), closed for modification (BaseAiWorker remains stable)
2. **Single Responsibility**: Each worker handles one specific customer intent (greeting, lead qualification, product info, etc.)
3. **Fail-Safe**: Workers degrade gracefully when OpenAI API is unavailable
4. **Testable**: All workers can be tested with mocked OpenAI responses (VCR cassettes)
5. **Observable**: Comprehensive logging and monitoring built-in

---

## Class Structure

### Inheritance Hierarchy

```
BaseAiWorker (abstract)
├── GreetingWorker (concrete)
├── LeadQualificationWorker (concrete)
├── ProductInfoWorker (concrete)
├── FinancingInfoWorker (concrete)
└── AppointmentSchedulingWorker (concrete)
```

### Core Components

```ruby
# app/services/ai_workers/base_ai_worker.rb

module AiWorkers
  class BaseAiWorker
    # Public API
    def initialize(openai_client: nil, logger: Rails.logger)
      @openai_client = openai_client || default_openai_client
      @logger = logger
    end

    def can_handle?(message, conversation)
      raise NotImplementedError, "#{self.class} must implement #can_handle?"
    end

    def process(message, conversation)
      raise NotImplementedError, "#{self.class} must implement #process"
    end

    # Protected helpers
    protected

    def call_openai(prompt, conversation_context: [], model: 'gpt-4o-mini', temperature: 0.7, max_tokens: 500)
      # OpenAI API call with error handling
    end

    def build_conversation_context(conversation, limit: 10)
      # Builds message history for OpenAI context
    end

    def extract_customer_name(message)
      # Extracts name from message content
    end

    def log_worker_decision(decision, message, reason: nil)
      # Structured logging
    end

    def log_worker_processing(message, conversation, duration:, tokens_used: nil)
      # Performance logging
    end

    # Private implementation
    private

    def default_openai_client
      OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
    end

    def format_messages_for_openai(conversation_context)
      # Converts Chatwoot messages to OpenAI format
    end

    def handle_openai_error(error, fallback: nil)
      # Error handling with fallback responses
    end
  end
end
```

---

## Method Specifications

### Public Methods

#### `initialize(openai_client: nil, logger: Rails.logger)`

**Type**: Constructor
**Parameters**:
- `openai_client` (optional): OpenAI::Client instance (for testing with mocks)
- `logger` (optional): Logger instance (for custom logging)

**Purpose**: Initialize worker with OpenAI client and logger

**Example**:
```ruby
# Production
worker = GreetingWorker.new

# Testing with mock
mock_client = instance_double(OpenAI::Client)
worker = GreetingWorker.new(openai_client: mock_client)
```

---

#### `can_handle?(message, conversation) → Boolean`

**Type**: Abstract method (must be implemented by subclasses)
**Returns**: `true` if worker can handle this message, `false` otherwise

**Purpose**: Determine if this worker should process the message. This is the **routing decision point** in the Chain of Responsibility pattern.

**Implementation Guidelines**:
- Keep logic fast (< 50ms)
- Use keyword matching, regex, or simple heuristics
- Avoid OpenAI calls in this method (too slow)
- Return `false` early if conditions don't match

**Example Implementation** (GreetingWorker):
```ruby
def can_handle?(message, conversation)
  # Only handle first message in conversation
  return false if conversation.messages.incoming.count > 1

  # Check for greeting keywords
  content = message.content.downcase
  greeting_keywords = ['hola', 'buenas', 'buenos días', 'hi', 'hello', 'hey']

  greeting_keywords.any? { |keyword| content.start_with?(keyword) }
end
```

**Example Implementation** (LeadQualificationWorker):
```ruby
def can_handle?(message, conversation)
  # Only after greeting is complete
  return false if conversation.messages.count < 3

  # Check if we need to qualify lead
  custom_attrs = conversation.custom_attributes || {}
  return false if custom_attrs['lead_qualified'] == true

  # Check for qualifying intents
  content = message.content.downcase
  qualifying_keywords = ['información', 'precio', 'financiamiento', 'motos', 'modelos']

  qualifying_keywords.any? { |keyword| content.include?(keyword) }
end
```

---

#### `process(message, conversation) → String`

**Type**: Abstract method (must be implemented by subclasses)
**Returns**: Response message to send to customer (String)
**Raises**: `StandardError` if processing fails

**Purpose**: Process the message and generate an AI response using OpenAI API.

**Implementation Guidelines**:
- Use `call_openai` helper for API calls
- Build conversation context with `build_conversation_context`
- Extract customer intent from message
- Generate contextually relevant response
- Update conversation custom_attributes if needed
- Handle errors gracefully with fallback responses

**Example Implementation** (GreetingWorker):
```ruby
def process(message, conversation)
  start_time = Time.current

  # Build context
  context = build_conversation_context(conversation)
  customer_name = extract_customer_name(message)

  # Build prompt
  system_prompt = <<~PROMPT
    Eres el asistente virtual de GP Bikes, una tienda de motocicletas en México.

    Tu tarea es:
    1. Dar la bienvenida al cliente de forma amigable y profesional
    2. Presentarte como el asistente de GP Bikes
    3. Preguntar cómo puedes ayudarle

    Responde en español, máximo 3 líneas.
  PROMPT

  user_prompt = "El cliente dice: #{message.content}"

  # Call OpenAI
  response = call_openai(
    [
      { role: 'system', content: system_prompt },
      { role: 'user', content: user_prompt }
    ],
    model: 'gpt-4o-mini',
    temperature: 0.7,
    max_tokens: 200
  )

  # Log performance
  duration = Time.current - start_time
  log_worker_processing(message, conversation, duration: duration)

  response
rescue StandardError => e
  handle_openai_error(e, fallback: "¡Hola! Bienvenido a GP Bikes. ¿En qué puedo ayudarte?")
end
```

---

### Protected Helper Methods

#### `call_openai(messages, model:, temperature:, max_tokens:, conversation_context: []) → String`

**Type**: Protected helper method
**Parameters**:
- `messages`: Array of OpenAI message hashes `[{role: 'system', content: '...'}, ...]`
- `model`: OpenAI model name (default: 'gpt-4o-mini')
- `temperature`: Creativity parameter 0.0-2.0 (default: 0.7)
- `max_tokens`: Maximum response length (default: 500)
- `conversation_context`: Previous messages for context (default: [])

**Returns**: String response from OpenAI
**Raises**: `OpenAI::Error` (wrapped in StandardError)

**Purpose**: Centralized OpenAI API call with error handling, retries, and logging

**Implementation**:
```ruby
def call_openai(messages, model: 'gpt-4o-mini', temperature: 0.7, max_tokens: 500, conversation_context: [])
  # Merge conversation context with new messages
  full_messages = conversation_context + messages

  @logger.info("[AiWorker] Calling OpenAI API", {
    worker: self.class.name,
    model: model,
    messages_count: full_messages.size,
    max_tokens: max_tokens
  })

  response = @openai_client.chat(
    parameters: {
      model: model,
      messages: full_messages,
      temperature: temperature,
      max_tokens: max_tokens
    }
  )

  content = response.dig('choices', 0, 'message', 'content')
  tokens_used = response.dig('usage', 'total_tokens')

  @logger.info("[AiWorker] OpenAI API response received", {
    worker: self.class.name,
    tokens_used: tokens_used,
    response_length: content&.length
  })

  content
rescue OpenAI::Error => e
  @logger.error("[AiWorker] OpenAI API error", {
    worker: self.class.name,
    error: e.class.name,
    message: e.message
  })
  raise StandardError, "OpenAI API call failed: #{e.message}"
end
```

---

#### `build_conversation_context(conversation, limit: 10) → Array<Hash>`

**Type**: Protected helper method
**Parameters**:
- `conversation`: Conversation ActiveRecord object
- `limit`: Maximum number of messages to include (default: 10)

**Returns**: Array of OpenAI message hashes `[{role: 'user', content: '...'}, {role: 'assistant', content: '...'}]`

**Purpose**: Build conversation history for OpenAI context window

**Implementation**:
```ruby
def build_conversation_context(conversation, limit: 10)
  messages = conversation.messages
                         .where(message_type: [:incoming, :outgoing])
                         .where(private: false)
                         .order(created_at: :asc)
                         .last(limit)

  messages.map do |msg|
    role = msg.incoming? ? 'user' : 'assistant'
    { role: role, content: msg.content }
  end
end
```

**Example Output**:
```ruby
[
  { role: 'user', content: 'Hola, quiero información sobre motos' },
  { role: 'assistant', content: '¡Hola! Bienvenido a GP Bikes. ¿Qué tipo de moto te interesa?' },
  { role: 'user', content: 'Algo deportivo para ciudad' }
]
```

---

#### `extract_customer_name(message) → String | nil`

**Type**: Protected helper method
**Parameters**:
- `message`: Message ActiveRecord object

**Returns**: Customer name (String) or `nil` if not found

**Purpose**: Extract customer name from message content or contact record

**Implementation**:
```ruby
def extract_customer_name(message)
  # Try contact name first
  return message.sender.name if message.sender&.name.present?

  # Try to extract from message content
  # Pattern: "Mi nombre es Juan" or "Soy María"
  content = message.content
  name_patterns = [
    /mi nombre es (\w+)/i,
    /me llamo (\w+)/i,
    /soy (\w+)/i
  ]

  name_patterns.each do |pattern|
    match = content.match(pattern)
    return match[1].capitalize if match
  end

  nil
end
```

---

#### `log_worker_decision(decision, message, reason: nil)`

**Type**: Protected helper method
**Parameters**:
- `decision`: Symbol (`:can_handle` or `:cannot_handle`)
- `message`: Message ActiveRecord object
- `reason`: Optional string explaining decision

**Purpose**: Structured logging for worker routing decisions

**Implementation**:
```ruby
def log_worker_decision(decision, message, reason: nil)
  @logger.info("[AiWorker] Worker decision", {
    worker: self.class.name,
    decision: decision,
    message_id: message.id,
    conversation_id: message.conversation_id,
    content_preview: message.content&.truncate(50),
    reason: reason
  })
end
```

**Example Log Output**:
```json
{
  "timestamp": "2025-09-30T10:30:45Z",
  "level": "INFO",
  "message": "[AiWorker] Worker decision",
  "worker": "GreetingWorker",
  "decision": "can_handle",
  "message_id": 123,
  "conversation_id": 45,
  "content_preview": "Hola, quiero información sobre motos",
  "reason": "First message in conversation with greeting keyword"
}
```

---

#### `log_worker_processing(message, conversation, duration:, tokens_used: nil)`

**Type**: Protected helper method
**Parameters**:
- `message`: Message ActiveRecord object
- `conversation`: Conversation ActiveRecord object
- `duration`: Processing time in seconds (Float)
- `tokens_used`: OpenAI tokens consumed (Integer, optional)

**Purpose**: Log worker performance metrics

**Implementation**:
```ruby
def log_worker_processing(message, conversation, duration:, tokens_used: nil)
  @logger.info("[AiWorker] Worker processing complete", {
    worker: self.class.name,
    message_id: message.id,
    conversation_id: conversation.id,
    duration_ms: (duration * 1000).round(2),
    tokens_used: tokens_used,
    account_id: message.account_id
  })
end
```

---

### Private Methods

#### `default_openai_client() → OpenAI::Client`

**Type**: Private method
**Returns**: Configured OpenAI::Client instance

**Purpose**: Create default OpenAI client with API key from environment

**Implementation**:
```ruby
def default_openai_client
  api_key = ENV['OPENAI_API_KEY']

  if api_key.blank?
    @logger.warn("[AiWorker] OPENAI_API_KEY not set, workers will fail")
  end

  OpenAI::Client.new(access_token: api_key)
end
```

---

#### `handle_openai_error(error, fallback: nil) → String`

**Type**: Private method
**Parameters**:
- `error`: StandardError instance
- `fallback`: Optional fallback response string

**Returns**: Fallback response or raises error

**Purpose**: Handle OpenAI API errors gracefully

**Implementation**:
```ruby
def handle_openai_error(error, fallback: nil)
  @logger.error("[AiWorker] OpenAI error", {
    worker: self.class.name,
    error_class: error.class.name,
    error_message: error.message,
    backtrace: error.backtrace.first(5)
  })

  if fallback.present?
    @logger.info("[AiWorker] Using fallback response", {
      worker: self.class.name,
      fallback: fallback
    })
    return fallback
  end

  # Re-raise if no fallback provided
  raise error
end
```

---

## Error Handling Strategy

### Error Types

| Error Type | Cause | Handling Strategy |
|------------|-------|-------------------|
| `OpenAI::Error` | API rate limit, invalid API key | Log + return fallback response |
| `ActiveRecord::RecordNotFound` | Message/conversation deleted | Log + skip processing |
| `StandardError` | Unexpected errors | Log + re-raise (Sentry will capture) |
| `JSON::ParserError` | Invalid OpenAI response | Log + return fallback response |
| `Net::ReadTimeout` | API timeout | Log + retry once, then fallback |

### Retry Strategy

```ruby
def call_openai_with_retry(messages, max_retries: 1, **options)
  retries = 0

  begin
    call_openai(messages, **options)
  rescue Net::ReadTimeout, OpenAI::Error => e
    retries += 1
    if retries <= max_retries
      @logger.warn("[AiWorker] Retrying OpenAI call (#{retries}/#{max_retries})")
      sleep(2 ** retries)  # Exponential backoff
      retry
    else
      handle_openai_error(e, fallback: options[:fallback])
    end
  end
end
```

---

## Logging Strategy

### Log Levels

| Level | When to Use | Example |
|-------|-------------|---------|
| `DEBUG` | Development debugging | "OpenAI prompt: #{prompt}" |
| `INFO` | Normal operations | "Worker processing started" |
| `WARN` | Recoverable issues | "API key not set, using fallback" |
| `ERROR` | Failures that need attention | "OpenAI API call failed" |
| `FATAL` | Critical system errors | "Database connection lost" |

### Structured Logging Format

All logs use structured JSON format for easy parsing:

```ruby
@logger.info("[AiWorker] #{event_name}", {
  worker: self.class.name,
  message_id: message.id,
  conversation_id: conversation.id,
  account_id: account.id,
  duration_ms: duration,
  # ... additional context
})
```

### Key Metrics to Log

1. **Worker Selection**
   - Which worker was chosen
   - Why it was chosen
   - How many workers were evaluated

2. **OpenAI API Calls**
   - Model used
   - Tokens consumed
   - Response time
   - Success/failure

3. **Processing Performance**
   - Total processing time
   - Time breakdown (API call, DB queries, etc.)

4. **Errors**
   - Error type and message
   - Stack trace (first 5 lines)
   - Retry attempts

---

## Testing Strategy

### Unit Testing Approach

#### 1. Test Worker Routing (`can_handle?`)

```ruby
# spec/services/ai_workers/greeting_worker_spec.rb
RSpec.describe AiWorkers::GreetingWorker do
  describe '#can_handle?' do
    let(:worker) { described_class.new }

    context 'when message is first in conversation' do
      it 'returns true for greeting keyword' do
        message = create(:message, :incoming, content: 'Hola')
        conversation = message.conversation

        expect(worker.can_handle?(message, conversation)).to be true
      end

      it 'returns false for non-greeting message' do
        message = create(:message, :incoming, content: 'Cuánto cuesta?')
        conversation = message.conversation

        expect(worker.can_handle?(message, conversation)).to be false
      end
    end

    context 'when message is not first in conversation' do
      it 'returns false even with greeting keyword' do
        conversation = create(:conversation)
        create(:message, :incoming, conversation: conversation)  # First message
        message = create(:message, :incoming, content: 'Hola', conversation: conversation)

        expect(worker.can_handle?(message, conversation)).to be false
      end
    end
  end
end
```

#### 2. Test Worker Processing (`process`)

Use **VCR cassettes** to record/replay OpenAI API responses:

```ruby
# spec/services/ai_workers/greeting_worker_spec.rb
RSpec.describe AiWorkers::GreetingWorker do
  describe '#process' do
    let(:worker) { described_class.new }

    it 'generates greeting response', :vcr do
      message = create(:message, :incoming, content: 'Hola')
      conversation = message.conversation

      response = worker.process(message, conversation)

      expect(response).to include('GP Bikes')
      expect(response).to include('bienvenido')
    end

    it 'uses customer name when available', :vcr do
      contact = create(:contact, name: 'Juan Pérez')
      message = create(:message, :incoming, content: 'Hola', sender: contact)
      conversation = message.conversation

      response = worker.process(message, conversation)

      expect(response).to include('Juan')
    end

    it 'handles OpenAI API errors gracefully' do
      allow_any_instance_of(OpenAI::Client).to receive(:chat).and_raise(OpenAI::Error.new('Rate limit'))

      message = create(:message, :incoming, content: 'Hola')
      conversation = message.conversation

      response = worker.process(message, conversation)

      # Should return fallback response
      expect(response).to be_present
      expect(response).to include('Bienvenido')
    end
  end
end
```

#### 3. Test Helper Methods

```ruby
RSpec.describe AiWorkers::BaseAiWorker do
  let(:worker_class) do
    Class.new(described_class) do
      def can_handle?(message, conversation)
        true
      end

      def process(message, conversation)
        "test response"
      end
    end
  end

  let(:worker) { worker_class.new }

  describe '#build_conversation_context' do
    it 'builds OpenAI message format' do
      conversation = create(:conversation)
      create(:message, :incoming, content: 'Hola', conversation: conversation)
      create(:message, :outgoing, content: 'Bienvenido', conversation: conversation)

      context = worker.send(:build_conversation_context, conversation)

      expect(context).to eq([
        { role: 'user', content: 'Hola' },
        { role: 'assistant', content: 'Bienvenido' }
      ])
    end

    it 'limits context to specified number of messages' do
      conversation = create(:conversation)
      15.times { create(:message, :incoming, conversation: conversation) }

      context = worker.send(:build_conversation_context, conversation, limit: 5)

      expect(context.size).to eq(5)
    end
  end

  describe '#extract_customer_name' do
    it 'extracts name from contact' do
      contact = create(:contact, name: 'Juan Pérez')
      message = create(:message, sender: contact)

      name = worker.send(:extract_customer_name, message)

      expect(name).to eq('Juan Pérez')
    end

    it 'extracts name from message content' do
      message = create(:message, content: 'Hola, mi nombre es María')

      name = worker.send(:extract_customer_name, message)

      expect(name).to eq('María')
    end
  end
end
```

---

### Integration Testing

Test full flow from message creation to response:

```ruby
# spec/integration/ai_worker_integration_spec.rb
RSpec.describe 'AI Worker Integration' do
  it 'processes greeting message end-to-end', :vcr do
    # Create WhatsApp inbox
    inbox = create(:inbox, :whatsapp)
    conversation = create(:conversation, inbox: inbox)
    contact = create(:contact, name: 'Juan')
    conversation.update!(contact: contact)

    # Simulate incoming message
    message = create(:message, :incoming,
      content: 'Hola',
      conversation: conversation,
      inbox: inbox,
      sender: contact
    )

    # Process message
    processor = AiWorkers::MessageProcessor.new(message)
    processor.process

    # Verify response created
    response = conversation.messages.outgoing.last
    expect(response).to be_present
    expect(response.content).to include('GP Bikes')
  end
end
```

---

### VCR Configuration

```ruby
# spec/support/vcr.rb
VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Filter sensitive data
  config.filter_sensitive_data('<OPENAI_API_KEY>') { ENV['OPENAI_API_KEY'] }

  # Allow local connections
  config.ignore_localhost = true

  # Match requests by method, URI, and body
  config.default_cassette_options = {
    match_requests_on: [:method, :uri, :body],
    record: :once
  }
end
```

Usage:
```ruby
# Record cassette on first run, replay on subsequent runs
it 'calls OpenAI API', :vcr do
  # Test code that calls OpenAI
end
```

---

## Worker Implementation Examples

### Example 1: GreetingWorker

```ruby
# app/services/ai_workers/greeting_worker.rb
module AiWorkers
  class GreetingWorker < BaseAiWorker
    GREETING_KEYWORDS = %w[hola buenas buenos hey hi hello].freeze

    def can_handle?(message, conversation)
      # Only handle first message
      return false if conversation.messages.incoming.count > 1

      # Check for greeting keywords
      content = message.content.downcase
      GREETING_KEYWORDS.any? { |keyword| content.start_with?(keyword) }
    end

    def process(message, conversation)
      start_time = Time.current

      customer_name = extract_customer_name(message)
      greeting = customer_name.present? ? "¡Hola #{customer_name}!" : "¡Hola!"

      system_prompt = <<~PROMPT
        Eres el asistente virtual de GP Bikes, una tienda de motocicletas en México.

        Da una bienvenida amigable y profesional. Menciona que eres el asistente de GP Bikes
        y pregunta cómo puedes ayudar al cliente.

        Usa máximo 3 líneas. Sé amigable pero profesional.
      PROMPT

      response = call_openai(
        [
          { role: 'system', content: system_prompt },
          { role: 'user', content: message.content }
        ],
        model: 'gpt-4o-mini',
        temperature: 0.7,
        max_tokens: 200
      )

      # Mark greeting as complete
      conversation.custom_attributes ||= {}
      conversation.custom_attributes['greeting_completed'] = true
      conversation.save!

      duration = Time.current - start_time
      log_worker_processing(message, conversation, duration: duration)

      response
    rescue StandardError => e
      handle_openai_error(e,
        fallback: "#{greeting} Bienvenido a GP Bikes. ¿En qué puedo ayudarte?"
      )
    end
  end
end
```

---

### Example 2: LeadQualificationWorker

```ruby
# app/services/ai_workers/lead_qualification_worker.rb
module AiWorkers
  class LeadQualificationWorker < BaseAiWorker
    QUALIFICATION_KEYWORDS = %w[
      información precio financiamiento motos modelos
      comprar vender crédito
    ].freeze

    def can_handle?(message, conversation)
      # Skip if already qualified
      return false if conversation.custom_attributes&.dig('lead_qualified') == true

      # Need at least greeting exchange
      return false if conversation.messages.count < 3

      # Check for qualification keywords
      content = message.content.downcase
      QUALIFICATION_KEYWORDS.any? { |keyword| content.include?(keyword) }
    end

    def process(message, conversation)
      start_time = Time.current

      context = build_conversation_context(conversation, limit: 5)

      system_prompt = <<~PROMPT
        Eres el asistente de calificación de leads de GP Bikes.

        Tu tarea es:
        1. Identificar el interés del cliente (tipo de moto, presupuesto, urgencia)
        2. Hacer 2-3 preguntas de calificación (budget, timeframe, preferences)
        3. Ser conversacional y no interrogatorio

        IMPORTANTE: No inventes información de productos. Solo haz preguntas.

        Formato de respuesta:
        - Pregunta de seguimiento relevante
        - Máximo 4 líneas
      PROMPT

      response = call_openai(
        [{ role: 'system', content: system_prompt }] + context + [{ role: 'user', content: message.content }],
        model: 'gpt-4o-mini',
        temperature: 0.8,
        max_tokens: 300,
        conversation_context: context
      )

      # Extract qualification data (simple heuristics)
      update_lead_qualification(message, conversation)

      duration = Time.current - start_time
      log_worker_processing(message, conversation, duration: duration)

      response
    rescue StandardError => e
      handle_openai_error(e,
        fallback: "Para poder ayudarte mejor, ¿podrías decirme qué tipo de moto te interesa?"
      )
    end

    private

    def update_lead_qualification(message, conversation)
      custom_attrs = conversation.custom_attributes || {}

      # Simple keyword extraction (will be enhanced with OpenAI extraction later)
      content = message.content.downcase

      custom_attrs['mentioned_budget'] = true if content.match?(/\d{1,3},?\d{0,3}/)
      custom_attrs['mentioned_timeframe'] = true if content.match?(/semana|mes|meses|pronto|urgente/)
      custom_attrs['lead_qualified'] = true if custom_attrs['mentioned_budget'] && custom_attrs['mentioned_timeframe']

      conversation.update!(custom_attributes: custom_attrs)
    end
  end
end
```

---

## Dependencies

### Required Gems

Add to `Gemfile`:

```ruby
# AI/ML
gem 'ruby-openai', '~> 6.3'

# Testing
group :test do
  gem 'vcr', '~> 6.2'
  gem 'webmock', '~> 3.19'
end
```

Install:
```bash
bundle install
```

---

## Environment Variables

```bash
# .env
OPENAI_API_KEY=sk-proj-...

# Feature flags
GP_BIKES_AI_WORKERS_ENABLED=true
GP_BIKES_AI_WORKER_MODEL=gpt-4o-mini

# Monitoring
GP_BIKES_AI_WORKER_LOG_LEVEL=info
```

---

## Performance Considerations

### Expected Performance

| Operation | Target Time | Notes |
|-----------|-------------|-------|
| `can_handle?` | < 50ms | Fast keyword matching only |
| `process` (OpenAI call) | 1-3 seconds | Network latency + OpenAI processing |
| Total message processing | < 5 seconds | Acceptable for customer experience |

### Optimization Strategies

1. **Async Processing**: All AI Workers run in Sidekiq background jobs
2. **Caching**: Cache OpenAI responses for identical prompts (future enhancement)
3. **Model Selection**: Use `gpt-4o-mini` (fast + cheap) for most workers
4. **Context Limiting**: Only send last 10 messages to OpenAI
5. **Concurrent Processing**: Process multiple messages in parallel (separate jobs)

---

## Monitoring & Observability

### Key Metrics

1. **Worker Selection Rate**
   - % of messages handled by each worker
   - % of messages not handled by any worker

2. **Processing Time**
   - P50, P95, P99 latency
   - Broken down by worker type

3. **OpenAI API**
   - Request rate
   - Token usage
   - Error rate
   - Cost per conversation

4. **Error Rate**
   - Errors per worker
   - Fallback usage rate

### Logging for Monitoring

```ruby
# Example structured log for monitoring
{
  "timestamp": "2025-09-30T10:30:45Z",
  "service": "ai_workers",
  "worker": "GreetingWorker",
  "event": "processing_complete",
  "message_id": 123,
  "conversation_id": 45,
  "account_id": 1,
  "duration_ms": 1234,
  "tokens_used": 150,
  "model": "gpt-4o-mini",
  "success": true
}
```

---

## Security Considerations

### Data Privacy

1. **PII Handling**: Never log customer PII (names, phone numbers, emails)
2. **OpenAI Data Policy**: Customer messages sent to OpenAI (review data retention policy)
3. **API Key Security**: Store in environment variables, never commit to git

### Rate Limiting

```ruby
# Future enhancement: Rate limit per account
class BaseAiWorker
  def check_rate_limit(account)
    key = "ai_worker:rate_limit:#{account.id}"
    count = Redis::Alfred.get(key).to_i

    if count >= 100  # 100 requests per hour
      raise RateLimitExceeded, "Account #{account.id} exceeded AI Worker rate limit"
    end

    Redis::Alfred.incr(key)
    Redis::Alfred.expire(key, 3600) unless count > 0
  end
end
```

---

## Future Enhancements

### Phase 2 Features

1. **Multi-language Support**: Detect customer language and respond accordingly
2. **Conversation Memory**: Use Redis to cache conversation context
3. **A/B Testing**: Test different prompts and models
4. **Sentiment Analysis**: Detect customer frustration and escalate to human
5. **Product Knowledge Base**: RAG (Retrieval-Augmented Generation) with product catalog

### Phase 3 Features

6. **Voice Support**: Process audio messages (WhatsApp voice notes)
7. **Image Recognition**: Analyze customer-sent photos of motorcycles
8. **Proactive Engagement**: Initiate conversations based on customer behavior
9. **Human Handoff**: Seamless transfer to human agent with full context

---

## Appendix: Complete Code Examples

### MessageProcessor (Orchestrator)

```ruby
# app/services/ai_workers/message_processor.rb
module AiWorkers
  class MessageProcessor
    def initialize(message)
      @message = message
      @conversation = message.conversation
      @logger = Rails.logger
    end

    def process
      @logger.info("[AiWorker] Processing message", {
        message_id: @message.id,
        conversation_id: @conversation.id,
        content_preview: @message.content&.truncate(50)
      })

      worker = determine_worker

      if worker.nil?
        @logger.info("[AiWorker] No worker can handle message", {
          message_id: @message.id
        })
        return
      end

      response = worker.process(@message, @conversation)

      # Create outgoing message
      @conversation.messages.create!(
        content: response,
        message_type: :outgoing,
        inbox: @message.inbox,
        account: @message.account,
        sender: nil  # Bot message (no sender)
      )

      @logger.info("[AiWorker] Response sent", {
        message_id: @message.id,
        worker: worker.class.name
      })
    rescue StandardError => e
      @logger.error("[AiWorker] Processing failed", {
        message_id: @message.id,
        error: e.class.name,
        message: e.message,
        backtrace: e.backtrace.first(5)
      })
      # Don't re-raise - we don't want to retry failed AI processing
    end

    private

    def determine_worker
      workers = [
        GreetingWorker.new,
        LeadQualificationWorker.new,
        ProductInfoWorker.new,
        FinancingInfoWorker.new,
        AppointmentSchedulingWorker.new
      ]

      workers.find do |worker|
        can_handle = worker.can_handle?(@message, @conversation)

        @logger.debug("[AiWorker] Worker evaluation", {
          worker: worker.class.name,
          can_handle: can_handle
        })

        can_handle
      end
    end
  end
end
```

---

## Summary

**BaseAiWorker** provides:
- ✅ Standardized interface for all AI workers (`can_handle?`, `process`)
- ✅ OpenAI integration with error handling
- ✅ Conversation context building
- ✅ Comprehensive logging and monitoring
- ✅ Testability with VCR cassettes
- ✅ Fail-safe fallback responses
- ✅ Performance optimization patterns

**Next Steps**:
1. ✅ Complete: Design document
2. ⏳ Create directory structure (Tarea 3)
3. ⏳ Implement BaseAiWorker (Tarea 4)
4. ⏳ Implement MessageProcessor (Tarea 5)
5. ⏳ Implement GreetingWorker (Tarea 6)
6. ⏳ Write comprehensive tests (Tarea 7)

---

**Document Status**: ✅ Complete
**Review Status**: Pending review by Daniela (Backend Lead)
**Implementation Status**: Ready to proceed with Tarea 3 (Directory Structure)
