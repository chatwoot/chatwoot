# AI Workers

This directory contains all AI Worker implementations for GP Bikes.

## Overview

AI Workers are service objects that process incoming WhatsApp messages and generate intelligent responses using OpenAI's GPT models. They follow the **Chain of Responsibility** pattern, where each worker evaluates whether it can handle a message, and the first matching worker processes it.

## Architecture

```
app/services/ai_workers/
├── base_ai_worker.rb              # Abstract base class
├── message_processor.rb           # Orchestrator (Chain of Responsibility)
├── greeting_worker.rb             # Handles initial greetings
├── lead_qualification_worker.rb   # Qualifies leads with questions
├── product_info_worker.rb         # Provides motorcycle information
├── financing_info_worker.rb       # Explains financing options
└── appointment_scheduling_worker.rb # Schedules showroom visits
```

## How It Works

### 1. Message Flow

```
WhatsApp → Chatwoot → MESSAGE_CREATED event → AiWorkerListener → MessageProcessorJob → MessageProcessor → [Worker 1, Worker 2, ...] → OpenAI → Response
```

### 2. Worker Selection (Chain of Responsibility)

```ruby
workers = [
  GreetingWorker.new,
  LeadQualificationWorker.new,
  ProductInfoWorker.new,
  # ...
]

worker = workers.find { |w| w.can_handle?(message, conversation) }
response = worker.process(message, conversation) if worker
```

### 3. Worker Interface

Every worker must implement:

```ruby
class MyWorker < BaseAiWorker
  # Determine if this worker should handle the message
  def can_handle?(message, conversation)
    # Return true/false
  end

  # Process the message and return response
  def process(message, conversation)
    # Return String response
  end
end
```

## Creating a New Worker

### Step 1: Create Worker File

```bash
touch app/services/ai_workers/my_new_worker.rb
```

### Step 2: Implement Worker Class

```ruby
# app/services/ai_workers/my_new_worker.rb
module AiWorkers
  class MyNewWorker < BaseAiWorker
    def can_handle?(message, conversation)
      # Example: Check for specific keywords
      content = message.content.downcase
      keywords = ['keyword1', 'keyword2']

      keywords.any? { |keyword| content.include?(keyword) }
    end

    def process(message, conversation)
      # Build OpenAI prompt
      system_prompt = <<~PROMPT
        You are an assistant for GP Bikes.
        Your task is to...
      PROMPT

      # Call OpenAI
      response = call_openai(
        [
          { role: 'system', content: system_prompt },
          { role: 'user', content: message.content }
        ],
        model: 'gpt-4o-mini',
        temperature: 0.7,
        max_tokens: 300
      )

      response
    rescue StandardError => e
      handle_openai_error(e, fallback: "Default response if API fails")
    end
  end
end
```

### Step 3: Register Worker in MessageProcessor

```ruby
# app/services/ai_workers/message_processor.rb
def workers
  [
    GreetingWorker.new,
    LeadQualificationWorker.new,
    # ... existing workers ...
    MyNewWorker.new  # Add your worker here
  ]
end
```

### Step 4: Write Tests

```ruby
# spec/services/ai_workers/my_new_worker_spec.rb
RSpec.describe AiWorkers::MyNewWorker do
  describe '#can_handle?' do
    it 'returns true when keywords match' do
      message = create(:message, content: 'keyword1')
      conversation = message.conversation
      worker = described_class.new

      expect(worker.can_handle?(message, conversation)).to be true
    end
  end

  describe '#process', :vcr do
    it 'generates response' do
      message = create(:message, content: 'keyword1')
      conversation = message.conversation
      worker = described_class.new

      response = worker.process(message, conversation)

      expect(response).to be_present
    end
  end
end
```

## Available Helper Methods (from BaseAiWorker)

### `call_openai(messages, model:, temperature:, max_tokens:)`
Makes OpenAI API call with error handling.

```ruby
response = call_openai(
  [{ role: 'system', content: 'You are...' }],
  model: 'gpt-4o-mini',
  temperature: 0.7,
  max_tokens: 500
)
```

### `build_conversation_context(conversation, limit: 10)`
Builds message history for OpenAI context window.

```ruby
context = build_conversation_context(conversation, limit: 5)
# => [{ role: 'user', content: '...' }, { role: 'assistant', content: '...' }]
```

### `extract_customer_name(message)`
Extracts customer name from contact or message content.

```ruby
name = extract_customer_name(message)
# => "Juan" or nil
```

### `log_worker_decision(decision, message, reason: nil)`
Logs worker routing decision.

```ruby
log_worker_decision(:can_handle, message, reason: "Greeting keyword found")
```

### `handle_openai_error(error, fallback: nil)`
Handles OpenAI errors with optional fallback response.

```ruby
rescue StandardError => e
  handle_openai_error(e, fallback: "Sorry, I'm having trouble. Can you try again?")
end
```

## Testing

### Unit Tests

Test worker logic in isolation:

```bash
bundle exec rspec spec/services/ai_workers/my_worker_spec.rb
```

### Integration Tests

Test full message processing flow:

```bash
bundle exec rspec spec/integration/ai_worker_integration_spec.rb
```

### VCR Cassettes

Record/replay OpenAI API responses:

```ruby
# First run: Records API response to spec/vcr_cassettes/
# Subsequent runs: Replays recorded response (no API call)

it 'calls OpenAI', :vcr do
  # Test code
end
```

To re-record cassettes:
```bash
rm spec/vcr_cassettes/my_cassette.yml
bundle exec rspec spec/services/ai_workers/my_worker_spec.rb
```

## Configuration

### Environment Variables

```bash
# Required
OPENAI_API_KEY=sk-proj-...

# Optional
GP_BIKES_AI_WORKERS_ENABLED=true
GP_BIKES_AI_WORKER_MODEL=gpt-4o-mini
GP_BIKES_AI_WORKER_LOG_LEVEL=info
```

### Feature Flags

Enable/disable AI Workers per account:

```ruby
# In Rails console
account = Account.find(1)
account.enable_features('gp_bikes_ai_workers')
```

## Monitoring

### Key Metrics

View in logs (structured JSON):

- Worker selection rate
- Processing time (P50, P95, P99)
- OpenAI API usage (tokens, cost)
- Error rate
- Fallback usage

### Example Log Entry

```json
{
  "timestamp": "2025-09-30T10:30:45Z",
  "level": "INFO",
  "message": "[AiWorker] Worker processing complete",
  "worker": "GreetingWorker",
  "message_id": 123,
  "conversation_id": 45,
  "duration_ms": 1234,
  "tokens_used": 150,
  "model": "gpt-4o-mini",
  "success": true
}
```

## Troubleshooting

### Worker Not Processing Messages

1. Check feature flag: `account.feature_enabled?('gp_bikes_ai_workers')`
2. Check environment variable: `ENV['GP_BIKES_AI_WORKERS_ENABLED']`
3. Check logs for worker evaluation: `grep "Worker evaluation" log/production.log`

### OpenAI API Errors

1. Verify API key: `ENV['OPENAI_API_KEY']`
2. Check rate limits in OpenAI dashboard
3. Review error logs: `grep "OpenAI error" log/production.log`

### Worker Not Selected

1. Check `can_handle?` logic in worker
2. Verify message matches criteria
3. Check worker order in MessageProcessor (first matching worker wins)

## Best Practices

### 1. Keep `can_handle?` Fast

- Use simple keyword matching
- Avoid OpenAI API calls
- Target < 50ms execution time

### 2. Use Fallback Responses

Always provide fallback for OpenAI errors:

```ruby
rescue StandardError => e
  handle_openai_error(e, fallback: "I'm having trouble. Can you rephrase that?")
end
```

### 3. Log Important Decisions

```ruby
log_worker_decision(:can_handle, message, reason: "First message with greeting")
```

### 4. Update Conversation Metadata

Track conversation state:

```ruby
conversation.custom_attributes ||= {}
conversation.custom_attributes['greeting_completed'] = true
conversation.save!
```

### 5. Limit Conversation Context

Don't send entire conversation history:

```ruby
context = build_conversation_context(conversation, limit: 10)  # Last 10 messages only
```

## Documentation

- [Webhook Flow Analysis](/docs/architecture/chatwoot-webhook-flow.md)
- [BaseAiWorker Design](/docs/architecture/BASE_AI_WORKER_DESIGN.md)
- [OpenAI API Docs](https://platform.openai.com/docs/api-reference)

## Related Files

- `app/listeners/ai_worker_listener.rb` - Event listener that triggers AI Workers
- `app/jobs/ai_workers/message_processor_job.rb` - Background job wrapper
- `spec/support/ai_workers/` - Shared test helpers

---

**Last Updated**: 2025-09-30
**Maintainer**: Simón (AI Worker Architect)
