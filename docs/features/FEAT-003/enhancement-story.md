# FEAT-003: Audio Transcription Enhancement - Implementation Story

## Epic Overview

### Summary
Enhance the existing audio transcription feature (FEAT-003) to support multi-channel audio processing, integration-based API key management, background job processing, language detection, and retry mechanisms. This evolution transforms the current API-only, synchronous transcription into a robust, scalable, multi-channel feature that provides real-time updates and better resilience.

### Business Value
- **Multi-Channel Support**: Transcribe audio from all channels (Widget, WhatsApp, Email, etc.), not just API
- **Scalability**: Non-blocking background processing improves response times and system throughput
- **Reliability**: Retry logic handles transient failures, improving success rates from ~95% to 99%+
- **Flexibility**: Per-account API key configuration allows granular control and usage tracking
- **Intelligence**: Language detection enables better routing and translation workflows

### Current State
- **Version**: 1.0 (commit `11d2bc818`)
- **Scope**: API messages controller only
- **Processing**: Synchronous (blocks message creation)
- **Configuration**: Global `ENV['OPENAI_API_KEY']` only
- **Error Handling**: Basic logging, no retries

### Target State
- **Scope**: All channels and message creation paths
- **Processing**: Asynchronous background jobs with real-time UI updates
- **Configuration**: Integration-based API keys with environment variable fallback
- **Error Handling**: Exponential backoff retries with comprehensive monitoring
- **Language Support**: Detection and metadata storage

---

## User Stories

### US-1: Integration-Based API Key Configuration
**As a** workspace administrator
**I want** to configure OpenAI API key per account through the integrations UI
**So that** I can track usage and costs per workspace and avoid global configuration dependencies

**Acceptance Criteria**:
- **Given** I have admin access to my account settings
- **When** I navigate to Integrations → OpenAI
- **Then** I can enter my OpenAI API key in the integration settings
- **And** audio transcriptions use my configured API key instead of the global environment variable
- **And** if no integration is configured, the system falls back to `ENV['OPENAI_API_KEY']`

### US-2: Multi-Channel Audio Transcription
**As a** support agent
**I want** audio messages from all channels to be automatically transcribed
**So that** I can read transcripts regardless of how customers send audio (Widget, WhatsApp, Email, etc.)

**Acceptance Criteria**:
- **Given** a customer sends an audio message via WhatsApp
- **When** the message is created in Chatwoot
- **Then** the audio is automatically transcribed and appended to message content
- **And** the same behavior occurs for Widget, Email, Telegram, and all other channels

### US-3: Background Job Processing
**As a** customer
**I want** my audio messages to be delivered immediately
**So that** I don't have to wait for transcription processing before my message appears

**Acceptance Criteria**:
- **Given** I send an audio message via the chat widget
- **When** the message is submitted
- **Then** the message appears in the conversation immediately with the audio attachment
- **And** the transcription is processed in the background
- **And** the transcription appears automatically when ready (within 30 seconds)
- **And** I see a visual indicator that transcription is in progress

### US-4: Language Detection and Metadata
**As a** support agent
**I want** to see what language was detected in audio transcriptions
**So that** I can route conversations appropriately and understand customer context

**Acceptance Criteria**:
- **Given** a customer sends audio in Spanish
- **When** the transcription is completed
- **Then** the detected language (Spanish) is stored as message metadata
- **And** I can optionally see the detected language in the UI
- **And** the language information is available for automation rules and routing

### US-5: Automatic Retry with Exponential Backoff
**As a** system administrator
**I want** failed transcriptions to be automatically retried
**So that** temporary API issues don't result in permanent transcription loss

**Acceptance Criteria**:
- **Given** OpenAI API returns a rate limit error (429)
- **When** the transcription job encounters the error
- **Then** the job retries after 2 seconds
- **And** if it fails again, retries after 4 seconds
- **And** if it fails again, retries after 8 seconds
- **And** if it fails after 3 retries, the error is logged and monitoring is alerted
- **And** the message remains accessible with its audio attachment

---

## Technical Design

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│ Message Creation (Any Channel)                                  │
│  - API Controller                                                │
│  - Widget                                                        │
│  - WhatsApp                                                      │
│  - Email                                                         │
│  - Telegram, etc.                                                │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ Message Model (after_create_commit)                             │
│  - Dispatches MESSAGE_CREATED event via Rails dispatcher        │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ AudioTranscriptionListener                                       │
│  - Subscribes to MESSAGE_CREATED events                         │
│  - Checks if message has audio attachments                      │
│  - Enqueues TranscribeAudioMessageJob                           │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ TranscribeAudioMessageJob (Sidekiq)                             │
│  - Retrieves message and attachments                            │
│  - Calls enhanced AudioTranscriptionService                     │
│  - Updates message content with transcription                   │
│  - Broadcasts update via ActionCable                            │
│  - Stores language metadata                                     │
│  - Implements retry logic with exponential backoff              │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ Openai::AudioTranscriptionService (Enhanced)                    │
│  - Resolves API key (Integration → Environment Variable)        │
│  - Downloads audio file                                         │
│  - Calls OpenAI Whisper API with verbose_json format           │
│  - Returns transcription + language + duration metadata         │
│  - Handles errors with proper exceptions                        │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ ActionCable Broadcast                                           │
│  - Pushes transcription update to connected clients             │
│  - Updates UI in real-time without page refresh                 │
└─────────────────────────────────────────────────────────────────┘
```

### Component Changes

#### 1. Enhanced AudioTranscriptionService
**File**: `app/services/openai/audio_transcription_service.rb`

**New Capabilities**:
- Integration-based API key resolution
- Language detection via `response_format: 'verbose_json'`
- Custom exception classes for better error handling
- Structured response object instead of plain string

**New Response Structure**:
```ruby
{
  text: "Transcribed content...",
  language: "es",
  duration: 12.5
}
```

**API Key Resolution Logic**:
```ruby
def resolve_api_key(account)
  # 1. Try integration hook
  integration = account.hooks.find_by(app_id: 'openai', status: 'enabled')
  return integration.settings['api_key'] if integration&.settings&.dig('api_key').present?

  # 2. Fall back to environment variable
  ENV.fetch('OPENAI_API_KEY', nil)
end
```

#### 2. New AudioTranscriptionListener
**File**: `app/listeners/audio_transcription_listener.rb`

**Responsibilities**:
- Subscribe to `MESSAGE_CREATED` event
- Detect audio attachments in messages
- Enqueue background job for transcription
- Check if transcription is enabled (feature flag + API key)

**Event Flow**:
```ruby
class AudioTranscriptionListener < BaseListener
  def message_created(event)
    message = event.data[:message]

    return unless should_transcribe?(message)

    message.attachments.each do |attachment|
      next unless audio_attachment?(attachment)

      TranscribeAudioMessageJob.perform_later(message.id, attachment.id)
    end
  end

  private

  def should_transcribe?(message)
    # Check feature flag
    return false unless transcription_enabled?

    # Check API key availability
    return false unless api_key_available?(message.account)

    # Check for audio attachments
    message.attachments.any? { |a| audio_attachment?(a) }
  end
end
```

#### 3. New TranscribeAudioMessageJob
**File**: `app/jobs/transcribe_audio_message_job.rb`

**Responsibilities**:
- Process audio transcription asynchronously
- Update message content with transcription
- Store language metadata in message custom_attributes
- Broadcast updates via ActionCable
- Implement retry logic with exponential backoff

**Retry Strategy**:
```ruby
class TranscribeAudioMessageJob < ApplicationJob
  queue_as :default

  retry_on Openai::RateLimitError, wait: :exponentially_longer, attempts: 3
  retry_on Openai::NetworkError, wait: :exponentially_longer, attempts: 3
  discard_on Openai::InvalidFileError

  def perform(message_id, attachment_id)
    message = Message.find(message_id)
    attachment = Attachment.find(attachment_id)

    result = Openai::AudioTranscriptionService.new(
      audio_url: attachment.download_url,
      account: message.account
    ).process

    return unless result

    update_message_with_transcription(message, result)
    broadcast_transcription_update(message)
  end
end
```

#### 4. Controller Simplification
**File**: `app/controllers/api/v1/accounts/conversations/messages_controller.rb`

**Changes**:
- Remove `audio_attachment?` method
- Remove `process_audio_transcription` method
- Simplify `create` action to only handle message creation
- Let the listener pattern handle transcription

**Before**:
```ruby
def create
  transcription = process_audio_transcription if audio_attachment?
  merged_params = params.dup
  # ... complex logic
end
```

**After**:
```ruby
def create
  user = Current.user || @resource
  @message = Messages::MessageBuilder.new(user, @conversation, params).perform
rescue StandardError => e
  render_could_not_create_error(e.message)
end
```

### Database Changes

#### Migration 1: Add Language Metadata to Messages
```ruby
# db/migrate/YYYYMMDDHHMMSS_add_transcription_metadata_to_messages.rb
class AddTranscriptionMetadataToMessages < ActiveRecord::Migration[7.1]
  def change
    # Store transcription metadata in additional_attributes
    # No schema changes needed - using existing JSONB column

    # Example structure:
    # additional_attributes: {
    #   transcription: {
    #     language: 'es',
    #     duration: 12.5,
    #     confidence: 0.95,
    #     transcribed_at: '2025-01-04T10:30:00Z'
    #   }
    # }
  end
end
```

**No migration required** - we'll use the existing `additional_attributes` JSONB column on messages.

#### Migration 2: Add Transcription Status to Attachments (Optional)
```ruby
# db/migrate/YYYYMMDDHHMMSS_add_transcription_status_to_attachments.rb
class AddTranscriptionStatusToAttachments < ActiveRecord::Migration[7.1]
  def change
    add_column :attachments, :transcription_status, :integer, default: 0
    add_column :attachments, :transcription_error, :text

    # Enum values: pending, processing, completed, failed
  end
end
```

**Optional** - for tracking transcription state at attachment level.

### API Changes

#### Enhanced Integration Settings Schema
**File**: `config/integration/apps.yml`

```yaml
openai:
  id: openai
  logo: openai.png
  i18n_key: openai
  action: /openai
  hook_type: account
  allow_multiple_hooks: false
  settings_json_schema:
    {
      'type': 'object',
      'properties':
        {
          'api_key': { 'type': 'string' },
          'label_suggestion': { 'type': 'boolean' },
          'audio_transcription': { 'type': 'boolean' },  # NEW
          'language_detection': { 'type': 'boolean' },    # NEW
        },
      'required': ['api_key'],
      'additionalProperties': false,
    }
  settings_form_schema:
    [
      {
        'label': 'API Key',
        'type': 'text',
        'name': 'api_key',
        'validation': 'required',
      },
      {
        'label': 'Show label suggestions',
        'type': 'checkbox',
        'name': 'label_suggestion',
        'validation': '',
      },
      {
        'label': 'Enable audio transcription',          # NEW
        'type': 'checkbox',
        'name': 'audio_transcription',
        'validation': '',
      },
      {
        'label': 'Detect and store audio language',     # NEW
        'type': 'checkbox',
        'name': 'language_detection',
        'validation': '',
      },
    ]
  visible_properties: ['api_key', 'label_suggestion', 'audio_transcription', 'language_detection']
```

### ActionCable Updates

#### New Channel for Transcription Updates
**File**: `app/channels/room_channel.rb` (existing, enhanced)

**Broadcast Event**:
```ruby
# In TranscribeAudioMessageJob
ActionCable.server.broadcast(
  "messages:#{message.conversation_id}",
  {
    event: 'message.updated',
    data: {
      id: message.id,
      content: message.content,
      additional_attributes: message.additional_attributes
    }
  }
)
```

**Frontend Listener** (existing pattern, will auto-update):
```javascript
// app/javascript/dashboard/api/channel/messagesChannel.js
// Already handles message.updated events
```

---

## Implementation Tasks

### Phase 1: Integration-Based API Key Support (3-5 days)

#### Task 1.1: Enhance AudioTranscriptionService with API Key Resolution
**Files to Modify**:
- `app/services/openai/audio_transcription_service.rb`

**Changes**:
```ruby
class Openai::AudioTranscriptionService
  def initialize(audio_url, account: nil)
    @audio_url = audio_url
    @account = account
    @api_key = resolve_api_key
  end

  private

  def resolve_api_key
    # 1. Try integration
    if @account
      integration = @account.hooks.find_by(app_id: 'openai', status: 'enabled')
      return integration.settings['api_key'] if integration&.settings&.dig('api_key').present?
    end

    # 2. Fall back to ENV
    ENV.fetch('OPENAI_API_KEY', nil)
  end
end
```

**Acceptance Criteria**:
- [ ] Service accepts optional `account` parameter
- [ ] API key resolved from integration settings first
- [ ] Falls back to environment variable if no integration
- [ ] Logs which API key source was used (integration vs env)
- [ ] Unit tests cover all resolution paths

#### Task 1.2: Update Integration Configuration
**Files to Modify**:
- `config/integration/apps.yml`

**Changes**:
- Add `audio_transcription` checkbox field
- Add `language_detection` checkbox field
- Update `visible_properties` to include new fields

**Acceptance Criteria**:
- [ ] Integration settings UI shows new checkboxes
- [ ] Settings validation passes with new fields
- [ ] Backward compatible with existing integrations

#### Task 1.3: Add Integration Tests
**Files to Create**:
- `spec/services/openai/audio_transcription_service_spec.rb` (update)

**Test Cases**:
- Integration API key takes precedence
- Falls back to ENV when no integration
- Returns nil when no API key available
- Logs appropriate messages for each scenario

### Phase 2: Multi-Channel Support via Listener Pattern (5-7 days)

#### Task 2.1: Create AudioTranscriptionListener
**Files to Create**:
- `app/listeners/audio_transcription_listener.rb`

**Implementation**:
```ruby
class AudioTranscriptionListener < BaseListener
  def message_created(event)
    message = event.data[:message]

    return unless transcription_enabled?
    return unless has_audio_attachments?(message)
    return unless api_key_available?(message.account)

    message.attachments.where(file_type: :audio).find_each do |attachment|
      TranscribeAudioMessageJob.perform_later(message.id, attachment.id)
    end
  end

  private

  def transcription_enabled?
    ENV.fetch('AUDIO_TRANSCRIPTION_ENABLED', 'true') == 'true'
  end

  def has_audio_attachments?(message)
    message.attachments.any? { |a| a.file_type == 'audio' }
  end

  def api_key_available?(account)
    service = Openai::AudioTranscriptionService.new('dummy', account: account)
    service.send(:resolve_api_key).present?
  end
end
```

**Acceptance Criteria**:
- [ ] Listener subscribes to MESSAGE_CREATED event
- [ ] Detects audio attachments correctly
- [ ] Enqueues job only when appropriate
- [ ] Checks feature flag before processing
- [ ] Works for all message sources (API, Widget, channels)

#### Task 2.2: Register Listener with Rails Dispatcher
**Files to Modify**:
- `config/initializers/listeners.rb` (or create if missing)

**Changes**:
```ruby
Rails.configuration.to_prepare do
  Rails.configuration.dispatcher.subscribe(
    AudioTranscriptionListener.instance,
    :message_created
  )
end
```

**Acceptance Criteria**:
- [ ] Listener registered on Rails initialization
- [ ] Responds to MESSAGE_CREATED events
- [ ] No performance impact on message creation

#### Task 2.3: Remove Controller-Specific Logic
**Files to Modify**:
- `app/controllers/api/v1/accounts/conversations/messages_controller.rb`

**Changes**:
- Remove `audio_attachment?` method (lines 71-78)
- Remove `process_audio_transcription` method (lines 80-113)
- Simplify `create` action (lines 8-26)

**Acceptance Criteria**:
- [ ] Controller only handles message creation
- [ ] No transcription logic in controller
- [ ] Backward compatible behavior via listener
- [ ] Existing API tests still pass

#### Task 2.4: Integration Testing Across Channels
**Files to Create**:
- `spec/listeners/audio_transcription_listener_spec.rb`
- `spec/integration/multi_channel_transcription_spec.rb`

**Test Scenarios**:
- API message with audio triggers transcription
- Widget message with audio triggers transcription
- WhatsApp audio message triggers transcription
- Email with audio attachment triggers transcription

### Phase 3: Background Job Processing (4-6 days)

#### Task 3.1: Create TranscribeAudioMessageJob
**Files to Create**:
- `app/jobs/transcribe_audio_message_job.rb`

**Implementation**:
```ruby
class TranscribeAudioMessageJob < ApplicationJob
  queue_as :default

  # Retry logic configured here (see Task 5.1 for details)

  def perform(message_id, attachment_id)
    message = Message.find(message_id)
    attachment = Attachment.find(attachment_id)

    Rails.logger.info "Starting transcription for message #{message_id}, attachment #{attachment_id}"

    result = Openai::AudioTranscriptionService.new(
      attachment.download_url,
      account: message.account
    ).process

    return unless result

    update_message_with_transcription(message, result)
    store_transcription_metadata(message, result)
    broadcast_transcription_update(message)

    Rails.logger.info "Transcription completed for message #{message_id}"
  end

  private

  def update_message_with_transcription(message, result)
    current_content = message.content.presence || ''
    transcription_text = "\n\n#{result[:text]}"

    message.update!(
      content: current_content + transcription_text
    )
  end

  def store_transcription_metadata(message, result)
    metadata = message.additional_attributes || {}
    metadata['transcription'] = {
      language: result[:language],
      duration: result[:duration],
      transcribed_at: Time.current.iso8601
    }
    message.update!(additional_attributes: metadata)
  end

  def broadcast_transcription_update(message)
    ActionCable.server.broadcast(
      "messages:#{message.conversation_id}",
      {
        event: 'message.updated',
        data: message.push_event_data
      }
    )
  end
end
```

**Acceptance Criteria**:
- [ ] Job queued on default queue
- [ ] Processes transcription asynchronously
- [ ] Updates message content correctly
- [ ] Stores metadata in additional_attributes
- [ ] Broadcasts update via ActionCable
- [ ] Handles missing message/attachment gracefully

#### Task 3.2: ActionCable Broadcast Integration
**Files to Modify**:
- `app/jobs/transcribe_audio_message_job.rb` (from 3.1)

**Verify**:
- Existing `RoomChannel` handles message.updated events
- Frontend components auto-update on broadcast

**Acceptance Criteria**:
- [ ] Broadcast sent after transcription
- [ ] Message updated in real-time in UI
- [ ] No page refresh required
- [ ] Works across all conversation views

#### Task 3.3: Frontend Loading State (Optional)
**Files to Modify** (if needed):
- `app/javascript/dashboard/components/widgets/conversation/Message.vue`

**Enhancement**:
- Show "Transcribing..." indicator for audio messages
- Update indicator when transcription arrives
- Handle transcription failures gracefully

**Acceptance Criteria**:
- [ ] Visual indicator for pending transcriptions
- [ ] Smooth transition when transcription arrives
- [ ] Error state displayed on failure

### Phase 4: Language Detection and Metadata (3-4 days)

#### Task 4.1: Enhance Service for Language Detection
**Files to Modify**:
- `app/services/openai/audio_transcription_service.rb`

**Changes**:
```ruby
def request_transcription(audio_file)
  response = self.class.post(
    '/audio/transcriptions',
    headers: { 'Authorization' => "Bearer #{@api_key}" },
    body: {
      model: 'whisper-1',
      file: audio_file,
      response_format: 'verbose_json'  # Changed from default
    },
    multipart: true
  )

  if response.success?
    parsed = response.parsed_response
    {
      text: parsed['text'],
      language: parsed['language'],
      duration: parsed['duration']
    }
  else
    # Error handling...
  end
end
```

**Acceptance Criteria**:
- [ ] Request uses `verbose_json` format
- [ ] Response includes language code
- [ ] Response includes duration
- [ ] Returns structured hash instead of string
- [ ] Backward compatible with existing callers

#### Task 4.2: Store Language in Message Metadata
**Files to Modify**:
- `app/jobs/transcribe_audio_message_job.rb` (already done in 3.1)

**Verify**:
- `additional_attributes['transcription']['language']` stored
- Language code follows ISO 639-1 standard
- Available for automation rules and reporting

#### Task 4.3: Optional UI Display
**Files to Modify** (optional):
- `app/javascript/dashboard/components/widgets/conversation/Message.vue`

**Enhancement**:
- Display language badge for transcribed messages
- Example: "🌐 Spanish" or "Detected: ES"

**Acceptance Criteria**:
- [ ] Language displayed if available
- [ ] Proper language name from code
- [ ] Only shown when metadata exists

### Phase 5: Retry Logic with Exponential Backoff (2-3 days)

#### Task 5.1: Add Custom Exception Classes
**Files to Create**:
- `app/services/openai/exceptions.rb`

**Implementation**:
```ruby
module Openai
  class TranscriptionError < StandardError; end
  class RateLimitError < TranscriptionError; end
  class NetworkError < TranscriptionError; end
  class InvalidFileError < TranscriptionError; end
  class AuthenticationError < TranscriptionError; end
end
```

**Acceptance Criteria**:
- [ ] Exception hierarchy defined
- [ ] Each exception represents specific failure
- [ ] Can be rescued independently

#### Task 5.2: Enhance Service Error Handling
**Files to Modify**:
- `app/services/openai/audio_transcription_service.rb`

**Changes**:
```ruby
def request_transcription(audio_file)
  response = self.class.post(...)

  case response.code
  when 200..299
    # Success - return data
  when 429
    raise Openai::RateLimitError, "Rate limit exceeded: #{response.body}"
  when 400
    raise Openai::InvalidFileError, "Invalid file: #{response.body}"
  when 401, 403
    raise Openai::AuthenticationError, "Auth failed: #{response.body}"
  when 500..599
    raise Openai::NetworkError, "Server error: #{response.body}"
  else
    raise Openai::TranscriptionError, "Unknown error: #{response.code}"
  end
rescue Net::OpenTimeout, Net::ReadTimeout => e
  raise Openai::NetworkError, "Network timeout: #{e.message}"
end
```

**Acceptance Criteria**:
- [ ] Specific exceptions raised for each error type
- [ ] Includes original error details
- [ ] Network timeouts handled
- [ ] Logged appropriately

#### Task 5.3: Configure Job Retry Strategy
**Files to Modify**:
- `app/jobs/transcribe_audio_message_job.rb`

**Changes**:
```ruby
class TranscribeAudioMessageJob < ApplicationJob
  queue_as :default

  # Retry rate limits and network errors with exponential backoff
  retry_on Openai::RateLimitError,
    wait: :exponentially_longer,  # 2s, 4s, 8s
    attempts: 3

  retry_on Openai::NetworkError,
    wait: :exponentially_longer,
    attempts: 3

  # Don't retry permanent failures
  discard_on Openai::InvalidFileError
  discard_on Openai::AuthenticationError

  # Track failures
  discard_on ActiveJob::DeserializationError do |job, error|
    Rails.logger.error "Transcription job failed: #{error.message}"
  end
end
```

**Acceptance Criteria**:
- [ ] Retries transient errors (rate limit, network)
- [ ] Uses exponential backoff (2s, 4s, 8s)
- [ ] Maximum 3 retry attempts
- [ ] Discards permanent failures immediately
- [ ] Logs final failure with details

#### Task 5.4: Add Monitoring and Alerts
**Files to Modify**:
- `app/jobs/transcribe_audio_message_job.rb`

**Add**:
```ruby
rescue_from(StandardError) do |exception|
  Rails.logger.error "Transcription failed permanently: #{exception.message}"
  Rails.logger.error exception.backtrace.join("\n")

  # Optional: Send to error tracking (Sentry, Rollbar, etc.)
  # Sentry.capture_exception(exception) if defined?(Sentry)

  # Optional: Increment failure metric
  # StatsD.increment('transcription.failure')
end
```

**Acceptance Criteria**:
- [ ] Failures logged with full context
- [ ] Errors reported to monitoring service
- [ ] Metrics tracked for dashboards
- [ ] Alerts configured for high failure rates

### Phase 6: Testing and Quality Assurance (3-5 days)

#### Task 6.1: Unit Tests
**Files to Create/Update**:
- `spec/services/openai/audio_transcription_service_spec.rb`
- `spec/listeners/audio_transcription_listener_spec.rb`
- `spec/jobs/transcribe_audio_message_job_spec.rb`

**Coverage**:
- Service API key resolution paths
- Service response parsing (verbose_json)
- Service error handling and exceptions
- Listener event subscription
- Listener audio detection logic
- Job retry behavior
- Job broadcast functionality

**Acceptance Criteria**:
- [ ] 100% code coverage for new code
- [ ] All edge cases tested
- [ ] Mock/stub external API calls
- [ ] Fast test execution (<10s total)

#### Task 6.2: Integration Tests
**Files to Create**:
- `spec/integration/audio_transcription_flow_spec.rb`

**Scenarios**:
```ruby
describe 'Audio Transcription Flow' do
  it 'transcribes API message with audio' do
    # Create message via API
    # Verify job enqueued
    # Process job
    # Verify message updated
    # Verify broadcast sent
  end

  it 'uses integration API key over environment' do
    # Setup integration
    # Create message
    # Verify correct API key used
  end

  it 'retries on rate limit' do
    # Stub rate limit response
    # Process job
    # Verify retry with backoff
  end
end
```

**Acceptance Criteria**:
- [ ] End-to-end flows tested
- [ ] Multi-channel scenarios covered
- [ ] Retry logic verified
- [ ] API key precedence confirmed

#### Task 6.3: Manual Testing Checklist
**Test Scenarios**:
- [ ] Send audio via API (existing behavior)
- [ ] Send audio via Widget
- [ ] Send audio via WhatsApp
- [ ] Send audio via Email attachment
- [ ] Configure integration API key
- [ ] Verify integration key takes precedence
- [ ] Remove integration, verify ENV fallback
- [ ] Trigger rate limit, verify retry
- [ ] Check language detection works
- [ ] Verify ActionCable real-time updates
- [ ] Test with no API key configured
- [ ] Test with invalid audio file
- [ ] Test with very long audio (>5 min)
- [ ] Monitor Sidekiq dashboard during processing
- [ ] Check logs for proper error handling

#### Task 6.4: Performance Testing
**Scenarios**:
- Concurrent transcriptions (10 simultaneous)
- High volume (100 messages in 1 minute)
- Large files (20+ MB audio)
- Memory profiling during batch processing

**Acceptance Criteria**:
- [ ] No memory leaks
- [ ] Sidekiq queue doesn't back up
- [ ] Response times acceptable (<30s P95)
- [ ] System handles load gracefully

### Phase 7: Documentation and Rollout (2-3 days)

#### Task 7.1: Update Feature Documentation
**Files to Modify**:
- `docs/features/FEAT-003/README.md`

**Updates**:
- Document multi-channel support
- Update architecture diagrams
- Add integration configuration guide
- Document language detection feature
- Update troubleshooting section

#### Task 7.2: Create Migration Guide
**Files to Create**:
- `docs/features/FEAT-003/migration-guide.md`

**Content**:
- What's changing
- Backward compatibility notes
- How to enable new features
- Integration setup instructions
- Rollback procedures

#### Task 7.3: API Documentation
**Files to Modify**:
- API docs (if applicable)

**Updates**:
- Document `additional_attributes.transcription` structure
- Note language metadata availability
- Update response examples

#### Task 7.4: Rollout Strategy
**Phases**:
1. **Week 1**: Deploy to staging, internal testing
2. **Week 2**: Enable for beta accounts with feature flag
3. **Week 3**: Gradual rollout to 25% → 50% → 100%
4. **Week 4**: Full release, monitor metrics

**Feature Flags**:
```ruby
# config/initializers/feature_flags.rb
AUDIO_TRANSCRIPTION_ENABLED = ENV.fetch('AUDIO_TRANSCRIPTION_ENABLED', 'true') == 'true'
AUDIO_TRANSCRIPTION_BACKGROUND = ENV.fetch('AUDIO_TRANSCRIPTION_BACKGROUND', 'true') == 'true'
```

**Rollback Plan**:
1. Set `AUDIO_TRANSCRIPTION_BACKGROUND=false` → reverts to sync processing
2. Set `AUDIO_TRANSCRIPTION_ENABLED=false` → disables feature entirely
3. No data loss - messages and audio preserved

---

## Testing Strategy

### Unit Testing

#### Service Layer Tests
```ruby
# spec/services/openai/audio_transcription_service_spec.rb
RSpec.describe Openai::AudioTranscriptionService do
  let(:audio_url) { 'https://example.com/audio.mp3' }
  let(:account) { create(:account) }

  describe '#process' do
    context 'with integration API key' do
      let!(:integration) do
        create(:integrations_hook,
          app_id: 'openai',
          account: account,
          settings: { 'api_key' => 'sk-integration-key' }
        )
      end

      it 'uses integration API key' do
        service = described_class.new(audio_url, account: account)
        expect(service.send(:resolve_api_key)).to eq('sk-integration-key')
      end
    end

    context 'with environment API key fallback' do
      before { allow(ENV).to receive(:fetch).with('OPENAI_API_KEY', nil).and_return('sk-env-key') }

      it 'falls back to environment variable' do
        service = described_class.new(audio_url, account: account)
        expect(service.send(:resolve_api_key)).to eq('sk-env-key')
      end
    end

    context 'with verbose_json response' do
      it 'returns structured data with language' do
        stub_openai_verbose_response(
          text: 'Hello world',
          language: 'en',
          duration: 2.5
        )

        result = described_class.new(audio_url, account: account).process
        expect(result).to include(
          text: 'Hello world',
          language: 'en',
          duration: 2.5
        )
      end
    end

    context 'error handling' do
      it 'raises RateLimitError on 429' do
        stub_openai_error(429, 'Rate limit exceeded')
        expect {
          described_class.new(audio_url, account: account).process
        }.to raise_error(Openai::RateLimitError)
      end

      it 'raises InvalidFileError on 400' do
        stub_openai_error(400, 'Invalid file format')
        expect {
          described_class.new(audio_url, account: account).process
        }.to raise_error(Openai::InvalidFileError)
      end
    end
  end
end
```

#### Listener Tests
```ruby
# spec/listeners/audio_transcription_listener_spec.rb
RSpec.describe AudioTranscriptionListener do
  describe '#message_created' do
    let(:message) { create(:message, :with_audio_attachment) }
    let(:event) { double(data: { message: message }) }

    context 'when transcription is enabled' do
      before { allow(ENV).to receive(:fetch).with('AUDIO_TRANSCRIPTION_ENABLED', 'true').and_return('true') }

      it 'enqueues transcription job' do
        expect(TranscribeAudioMessageJob).to receive(:perform_later)
          .with(message.id, message.attachments.first.id)

        described_class.instance.message_created(event)
      end
    end

    context 'when transcription is disabled' do
      before { allow(ENV).to receive(:fetch).with('AUDIO_TRANSCRIPTION_ENABLED', 'true').and_return('false') }

      it 'does not enqueue job' do
        expect(TranscribeAudioMessageJob).not_to receive(:perform_later)
        described_class.instance.message_created(event)
      end
    end

    context 'without audio attachments' do
      let(:message) { create(:message) }

      it 'does not enqueue job' do
        expect(TranscribeAudioMessageJob).not_to receive(:perform_later)
        described_class.instance.message_created(event)
      end
    end
  end
end
```

#### Job Tests
```ruby
# spec/jobs/transcribe_audio_message_job_spec.rb
RSpec.describe TranscribeAudioMessageJob do
  let(:message) { create(:message) }
  let(:attachment) { create(:attachment, :audio, message: message) }

  describe '#perform' do
    it 'updates message with transcription' do
      stub_successful_transcription(
        text: 'Transcribed text',
        language: 'en',
        duration: 5.0
      )

      described_class.new.perform(message.id, attachment.id)

      message.reload
      expect(message.content).to include('Transcribed text')
      expect(message.additional_attributes['transcription']['language']).to eq('en')
    end

    it 'broadcasts update via ActionCable' do
      stub_successful_transcription

      expect(ActionCable.server).to receive(:broadcast)
        .with("messages:#{message.conversation_id}", hash_including(event: 'message.updated'))

      described_class.new.perform(message.id, attachment.id)
    end
  end

  describe 'retry behavior' do
    it 'retries on rate limit error' do
      allow_any_instance_of(Openai::AudioTranscriptionService)
        .to receive(:process).and_raise(Openai::RateLimitError)

      expect {
        described_class.new.perform(message.id, attachment.id)
      }.to have_enqueued_job(described_class).on_queue('default')
    end

    it 'discards on invalid file error' do
      allow_any_instance_of(Openai::AudioTranscriptionService)
        .to receive(:process).and_raise(Openai::InvalidFileError)

      expect {
        described_class.new.perform(message.id, attachment.id)
      }.not_to have_enqueued_job(described_class)
    end
  end
end
```

### Integration Testing

```ruby
# spec/integration/audio_transcription_flow_spec.rb
RSpec.describe 'Audio Transcription Flow', type: :integration do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:conversation) { create(:conversation, account: account) }

  describe 'multi-channel support' do
    it 'transcribes API message with audio' do
      post api_v1_account_conversation_messages_url(
        account_id: account.id,
        conversation_id: conversation.id
      ), params: {
        content: 'Audio message',
        attachments: [fixture_file_upload('audio.mp3', 'audio/mpeg')]
      }, headers: user_headers

      expect(response).to have_http_status(:success)

      # Job should be enqueued
      expect(TranscribeAudioMessageJob).to have_been_enqueued

      # Process job
      perform_enqueued_jobs

      # Message should be updated
      message = conversation.messages.last
      expect(message.content).to include('Transcribed text')
    end

    it 'transcribes widget message with audio' do
      # Simulate widget message creation with audio
      # ... similar test for widget channel
    end
  end

  describe 'integration API key precedence' do
    let!(:integration) do
      create(:integrations_hook,
        app_id: 'openai',
        account: account,
        settings: { 'api_key' => 'sk-integration-key' }
      )
    end

    before do
      allow(ENV).to receive(:fetch).with('OPENAI_API_KEY', nil).and_return('sk-env-key')
    end

    it 'uses integration API key over environment' do
      # Create message with audio
      # Verify integration API key was used in request
      expect(last_api_request_header('Authorization')).to eq('Bearer sk-integration-key')
    end
  end
end
```

### Manual Testing Checklist

#### Pre-Release Testing
- [ ] **API Messages**: Send audio via API endpoint
- [ ] **Widget Messages**: Upload audio in chat widget
- [ ] **WhatsApp**: Forward WhatsApp voice note
- [ ] **Email**: Send email with audio attachment
- [ ] **Telegram**: Send Telegram voice message
- [ ] **Integration Config**: Configure OpenAI integration with API key
- [ ] **API Key Precedence**: Verify integration key used first
- [ ] **Environment Fallback**: Remove integration, verify ENV key used
- [ ] **No API Key**: Disable all keys, verify graceful degradation
- [ ] **Multiple Audio**: Send message with 2+ audio files
- [ ] **Mixed Content**: Send text + audio in one message
- [ ] **Language Detection**: Send Spanish audio, verify language detected
- [ ] **Real-time Update**: Watch transcription appear without refresh
- [ ] **Rate Limit**: Trigger rate limit (send many), verify retry
- [ ] **Invalid File**: Upload corrupted audio, verify error handling
- [ ] **Large File**: Upload 20+ MB audio file
- [ ] **Long Duration**: Upload 10+ minute audio
- [ ] **Sidekiq Dashboard**: Monitor job processing
- [ ] **Logs**: Check Rails logs for proper messages
- [ ] **Metrics**: Verify success/failure metrics tracked

#### Performance Testing
- [ ] **Concurrency**: Send 10 audio messages simultaneously
- [ ] **Volume**: Send 100 audio messages over 5 minutes
- [ ] **Memory**: Monitor memory usage during batch processing
- [ ] **Queue Depth**: Verify Sidekiq queue stays healthy
- [ ] **Response Time**: Measure P95 transcription latency
- [ ] **Database Load**: Check DB query patterns

#### Browser/Device Testing
- [ ] Chrome (desktop)
- [ ] Firefox (desktop)
- [ ] Safari (desktop)
- [ ] Mobile Safari (iOS)
- [ ] Chrome (Android)
- [ ] Widget embed on external site

---

## Migration and Rollback Strategy

### Migration Plan

#### Pre-Migration Checklist
- [ ] Backup database
- [ ] Review OpenAI API quota and rate limits
- [ ] Configure monitoring alerts
- [ ] Test rollback procedure in staging
- [ ] Document emergency contacts

#### Migration Steps

**Step 1: Deploy Code** (Maintenance Window: 30 min)
```bash
# 1. Deploy application with feature flag disabled
AUDIO_TRANSCRIPTION_BACKGROUND=false bin/deploy

# 2. Verify deployment successful
curl https://app.chatwoot.com/health

# 3. Run database migrations (if any)
bundle exec rails db:migrate

# 4. Restart workers
bundle exec rake sidekiq:restart
```

**Step 2: Enable for Internal Testing** (Week 1)
```bash
# Enable background processing for internal account only
# Via Rails console or feature flag service
Account.find_by(name: 'Internal').update(
  feature_flags: { audio_transcription_background: true }
)
```

**Step 3: Beta Rollout** (Week 2)
```bash
# Enable for 10 beta accounts
beta_accounts = Account.where(id: [...])
beta_accounts.update_all(
  feature_flags: { audio_transcription_background: true }
)
```

**Step 4: Gradual Rollout** (Week 3)
- Day 1: 25% of accounts
- Day 3: 50% of accounts
- Day 5: 75% of accounts
- Day 7: 100% of accounts

```bash
# Gradual rollout script
percentage = 25 # Increase daily
Account.where('id % 100 < ?', percentage).update_all(
  feature_flags: { audio_transcription_background: true }
)
```

**Step 5: Full Release** (Week 4)
```bash
# Enable globally via environment variable
AUDIO_TRANSCRIPTION_BACKGROUND=true

# Remove account-level overrides
Account.update_all("feature_flags = feature_flags - 'audio_transcription_background'")
```

### Rollback Procedures

#### Level 1: Disable Background Processing
**Impact**: Reverts to synchronous transcription (original behavior)
**Downtime**: None
**Steps**:
```bash
# 1. Set environment variable
export AUDIO_TRANSCRIPTION_BACKGROUND=false

# 2. Restart application
bin/restart

# 3. Monitor - transcriptions continue but synchronously
tail -f log/production.log | grep -i transcription
```

#### Level 2: Disable Transcription Entirely
**Impact**: No transcriptions, audio still saved
**Downtime**: None
**Steps**:
```bash
# 1. Disable feature globally
export AUDIO_TRANSCRIPTION_ENABLED=false

# 2. Restart application
bin/restart

# 3. Verify - no transcription jobs enqueued
# Audio messages still created normally
```

#### Level 3: Code Rollback
**Impact**: Revert to previous version
**Downtime**: 2-5 minutes
**Steps**:
```bash
# 1. Identify last stable version
git log --oneline

# 2. Rollback deployment
bin/rollback <previous_version>

# 3. Rollback database migrations (if any)
bundle exec rails db:rollback STEP=X

# 4. Restart all services
bin/restart_all

# 5. Verify functionality
bundle exec rspec spec/integration/audio_transcription_spec.rb
```

### Data Migration (If Needed)

#### Backfill Existing Audio Messages
**Scenario**: Add transcriptions to historical audio messages

```ruby
# lib/tasks/audio_transcription.rake
namespace :audio_transcription do
  desc 'Backfill transcriptions for existing audio messages'
  task backfill: :environment do
    start_date = ENV.fetch('START_DATE', 30.days.ago)

    Message.joins(:attachments)
      .where(attachments: { file_type: 'audio' })
      .where('messages.created_at >= ?', start_date)
      .where("messages.additional_attributes->>'transcription' IS NULL")
      .find_each do |message|
        message.attachments.where(file_type: 'audio').each do |attachment|
          TranscribeAudioMessageJob.perform_later(message.id, attachment.id)
        end
      end

    puts "Enqueued transcription jobs for historical messages"
  end
end
```

**Usage**:
```bash
# Backfill last 30 days
START_DATE="2024-12-01" bundle exec rails audio_transcription:backfill

# Monitor progress
bundle exec rails runner "puts TranscribeAudioMessageJob.jobs.count"
```

---

## Dependencies and Infrastructure

### Gem Dependencies

#### Existing (No Changes)
- `httparty` - HTTP client for OpenAI API
- `down` - File downloading
- `sidekiq` - Background job processing
- `actioncable` - WebSocket communication

#### Optional Future Enhancements
- `ruby-openai` - Official OpenAI SDK (could replace HTTParty implementation)

### Environment Variables

#### Required
```bash
# OpenAI API key (fallback if no integration configured)
OPENAI_API_KEY=sk-proj-...
```

#### Optional Configuration
```bash
# Feature flags
AUDIO_TRANSCRIPTION_ENABLED=true          # Enable/disable feature globally
AUDIO_TRANSCRIPTION_BACKGROUND=true       # Enable background processing

# OpenAI API settings
OPENAI_TIMEOUT=30                          # API request timeout (seconds)
OPENAI_MAX_FILE_SIZE=25000000             # Max file size (25MB default)

# Frontend URL (for audio file access)
FRONTEND_URL=https://app.chatwoot.com
```

### Infrastructure Requirements

#### Sidekiq Configuration
```ruby
# config/sidekiq.yml
:queues:
  - [critical, 5]
  - [default, 3]      # Transcription jobs use default queue
  - [low, 1]

:concurrency: 25      # Increase if high transcription volume
```

#### Redis Configuration
- No special requirements
- Existing Redis instance sufficient
- Monitor memory usage during peak transcription periods

#### OpenAI Account Setup
1. **API Key**: Generate at https://platform.openai.com/api-keys
2. **Rate Limits**:
   - Free tier: 3 requests/min
   - Tier 1: 3,500 requests/min (sufficient for most)
   - Tier 2+: Higher limits for enterprise
3. **Billing**: Enable billing, set monthly limits
4. **Monitoring**: Track usage at https://platform.openai.com/usage

### Monitoring and Observability

#### Metrics to Track
```ruby
# Example: StatsD/DataDog metrics
StatsD.increment('audio_transcription.job.enqueued')
StatsD.increment('audio_transcription.job.success')
StatsD.increment('audio_transcription.job.failure')
StatsD.increment('audio_transcription.retry.rate_limit')
StatsD.histogram('audio_transcription.duration', duration_seconds)
StatsD.histogram('audio_transcription.audio_duration', audio_duration)
```

#### Logging Standards
```ruby
# Structured logging example
Rails.logger.info({
  event: 'transcription.started',
  message_id: message.id,
  account_id: message.account_id,
  audio_duration: attachment.metadata['duration'],
  api_key_source: 'integration' # or 'environment'
}.to_json)
```

#### Alerts Configuration
- **Failure Rate >5%**: Page on-call engineer
- **Queue Depth >100**: Warning notification
- **API Errors >10/min**: Investigation alert
- **Average Latency >45s**: Performance degradation alert

---

## Risks and Mitigations

### Technical Risks

#### Risk 1: OpenAI API Rate Limiting
**Impact**: High volume of audio messages could exceed rate limits
**Probability**: Medium
**Mitigation**:
- Implement exponential backoff retry (done in Phase 5)
- Monitor daily usage trends
- Set up alerts at 80% of rate limit
- Consider queueing with delay during peak times
- Upgrade OpenAI tier if needed

#### Risk 2: Background Job Queue Backup
**Impact**: Slow transcription processing during high load
**Probability**: Low-Medium
**Mitigation**:
- Dedicated Sidekiq queue for transcriptions (optional)
- Scale Sidekiq workers based on queue depth
- Set job timeout limits (e.g., 2 minutes max)
- Monitor queue depth and latency

#### Risk 3: Large Audio Files
**Impact**: Memory issues, slow processing, high costs
**Probability**: Low
**Mitigation**:
- Validate file size before transcription (25MB max)
- Show user warning for files >10MB
- Consider compression before upload
- Track cost per transcription

#### Risk 4: ActionCable Broadcast Failures
**Impact**: UI doesn't update when transcription completes
**Probability**: Low
**Mitigation**:
- Graceful degradation - transcription still saved
- Client-side polling fallback (check every 30s)
- Comprehensive error logging
- Test WebSocket connectivity

#### Risk 5: Integration API Key Security
**Impact**: API key exposure or unauthorized usage
**Probability**: Low
**Mitigation**:
- Never log full API keys
- Encrypt settings in database (Rails encrypted attributes)
- Audit log for integration changes
- Automatic key rotation reminders

### Business Risks

#### Risk 1: Cost Overruns
**Impact**: Unexpected OpenAI billing
**Probability**: Medium
**Mitigation**:
- Set OpenAI account spending limits
- Track cost per account/conversation
- Alert at 80% of monthly budget
- Provide usage dashboards to admins
- Consider per-account quotas

#### Risk 2: Transcription Accuracy Issues
**Impact**: Poor transcriptions reduce feature value
**Probability**: Medium
**Mitigation**:
- Set expectations (90%+ accuracy for clear audio)
- Document supported languages
- Provide feedback mechanism
- Consider confidence scores in future
- Allow manual re-transcription

#### Risk 3: Privacy and Compliance
**Impact**: Audio data sent to OpenAI may violate regulations
**Probability**: Low-Medium
**Mitigation**:
- Document data processing in privacy policy
- Review OpenAI's DPA and BAA
- Provide opt-out per account
- Consider on-premise alternative for sensitive accounts
- GDPR/HIPAA compliance review

---

## Success Metrics and KPIs

### Feature Adoption Metrics
- **Transcription Coverage**: % of audio messages with transcriptions
  - Target: 95%+ (accounting for opt-outs and failures)
- **Multi-Channel Usage**: Breakdown by channel (API, Widget, WhatsApp, etc.)
  - Target: All channels >80% coverage
- **Integration Adoption**: % of accounts using integration API key vs ENV
  - Target: 50%+ within 3 months

### Performance Metrics
- **Transcription Success Rate**: % of successful transcriptions
  - Target: 99%+ (up from 95% with retry logic)
- **Processing Latency (P95)**: Time from message creation to transcription complete
  - Target: <30 seconds for 90% of messages
- **Queue Depth**: Average Sidekiq transcription queue depth
  - Target: <10 jobs during normal load
- **Retry Rate**: % of jobs requiring retry
  - Target: <10% (rate limits + network errors)

### Quality Metrics
- **Transcription Accuracy**: Manual review of sample transcriptions
  - Target: 90%+ word accuracy for clear audio
- **Language Detection Accuracy**: % correctly detected languages
  - Target: 95%+ for primary languages
- **User Satisfaction**: Agent feedback on feature usefulness
  - Target: 4.0+ / 5.0 rating

### Business Metrics
- **Cost Per Transcription**: Average OpenAI cost per audio message
  - Target: <$0.01 per message (depends on duration)
- **Time Saved**: Estimated time saved vs listening to audio
  - Target: 50%+ time reduction for audio-heavy accounts
- **Search Improvement**: Increase in searchable conversation content
  - Target: Measurable increase in search result relevance

### Monitoring Dashboard

#### Real-Time Panel
- Current transcription jobs (queued/processing/failed)
- Success rate (last hour/day/week)
- Average processing latency
- API error rate by type

#### Trends Panel
- Daily transcription volume
- Success rate trend
- Cost accumulation
- Language distribution

#### Alerts Panel
- Active incidents
- Recent failures with details
- Rate limit warnings
- Queue depth alerts

---

## Timeline and Milestones

### Phase 1: Integration API Key Support (Week 1)
- **Duration**: 3-5 days
- **Team**: 1 backend engineer
- **Deliverables**:
  - Enhanced AudioTranscriptionService with API key resolution
  - Updated integration configuration
  - Unit tests for new functionality
- **Milestone**: Integration API keys functional in staging

### Phase 2: Multi-Channel Support (Week 1-2)
- **Duration**: 5-7 days
- **Team**: 1 backend engineer
- **Deliverables**:
  - AudioTranscriptionListener implementation
  - Controller refactoring
  - Integration tests for all channels
- **Milestone**: Transcription works from Widget, WhatsApp, Email

### Phase 3: Background Job Processing (Week 2-3)
- **Duration**: 4-6 days
- **Team**: 1 backend engineer, 1 frontend engineer
- **Deliverables**:
  - TranscribeAudioMessageJob implementation
  - ActionCable broadcast integration
  - Optional UI loading states
- **Milestone**: Async transcription with real-time UI updates

### Phase 4: Language Detection (Week 3)
- **Duration**: 3-4 days
- **Team**: 1 backend engineer
- **Deliverables**:
  - Verbose JSON response parsing
  - Metadata storage in messages
  - Optional UI language display
- **Milestone**: Language detected and stored for all transcriptions

### Phase 5: Retry Logic (Week 3-4)
- **Duration**: 2-3 days
- **Team**: 1 backend engineer
- **Deliverables**:
  - Custom exception classes
  - Job retry configuration
  - Monitoring and alerting
- **Milestone**: Transient failures auto-retry with backoff

### Phase 6: Testing & QA (Week 4)
- **Duration**: 3-5 days
- **Team**: 1 QA engineer, 1 backend engineer
- **Deliverables**:
  - Comprehensive test coverage
  - Manual testing completion
  - Performance validation
- **Milestone**: Ready for production deployment

### Phase 7: Documentation & Rollout (Week 4-5)
- **Duration**: 2-3 days
- **Team**: 1 technical writer, 1 DevOps engineer
- **Deliverables**:
  - Updated documentation
  - Migration guide
  - Gradual rollout to production
- **Milestone**: Feature live for 100% of users

### Total Timeline: 4-5 Weeks
- **Sprint 1 (Week 1-2)**: Core functionality (Phases 1-2)
- **Sprint 2 (Week 3-4)**: Advanced features (Phases 3-5)
- **Sprint 3 (Week 5)**: Testing and rollout (Phases 6-7)

---

## Definition of Done

### Feature Complete Checklist

#### Code Quality
- [ ] All code follows Rails 7.1 and Vue 3 best practices
- [ ] RuboCop passes with no offenses
- [ ] ESLint passes with no errors
- [ ] Code reviewed and approved by 2+ engineers
- [ ] No TODO comments in production code

#### Testing
- [ ] Unit test coverage >90% for new code
- [ ] Integration tests cover all user stories
- [ ] Manual testing checklist completed
- [ ] Performance tests show acceptable latency (<30s P95)
- [ ] Load testing validates no memory leaks

#### Functionality
- [ ] Integration API key takes precedence over ENV
- [ ] Transcription works for all channels (API, Widget, WhatsApp, Email, etc.)
- [ ] Background jobs process asynchronously
- [ ] Real-time UI updates via ActionCable
- [ ] Language detection and metadata storage functional
- [ ] Retry logic handles rate limits and network errors
- [ ] Graceful degradation when API unavailable

#### Documentation
- [ ] Feature documentation updated (FEAT-003/README.md)
- [ ] Migration guide created
- [ ] API documentation reflects changes
- [ ] Code comments explain complex logic
- [ ] Troubleshooting guide updated

#### Operations
- [ ] Monitoring dashboards configured
- [ ] Alerts set up for failure rates and queue depth
- [ ] Logging provides adequate debugging info
- [ ] Rollback procedure tested in staging
- [ ] On-call runbook updated

#### Security & Compliance
- [ ] API keys never logged or exposed
- [ ] Integration settings encrypted in database
- [ ] Privacy policy updated (if needed)
- [ ] GDPR/compliance review completed
- [ ] Security team sign-off obtained

#### Deployment
- [ ] Deployed to staging and validated
- [ ] Beta tested with 10+ accounts
- [ ] Gradual rollout plan defined
- [ ] Feature flags configured
- [ ] Rollback tested successfully

#### User Experience
- [ ] Transcriptions appear within 30 seconds
- [ ] Visual indicators for processing state
- [ ] Error states handled gracefully
- [ ] No breaking changes to existing workflows
- [ ] Agent feedback collected and positive

### Release Approval

**Required Sign-offs**:
- [ ] Engineering Lead - Technical implementation
- [ ] Product Manager - Feature requirements met
- [ ] QA Lead - Testing complete
- [ ] Security Team - No security concerns
- [ ] DevOps - Infrastructure ready
- [ ] Support Lead - Documentation adequate

**Final Checklist**:
- [ ] All acceptance criteria met
- [ ] No P0/P1 bugs outstanding
- [ ] Monitoring and alerts active
- [ ] Support team trained
- [ ] Release notes published
- [ ] Stakeholders notified

---

## Appendix

### A. OpenAI API Request Examples

#### Standard Transcription Request
```bash
curl https://api.openai.com/v1/audio/transcriptions \
  -H "Authorization: Bearer sk-proj-..." \
  -H "Content-Type: multipart/form-data" \
  -F file="@audio.mp3" \
  -F model="whisper-1"
```

#### Verbose JSON Request (with Language Detection)
```bash
curl https://api.openai.com/v1/audio/transcriptions \
  -H "Authorization: Bearer sk-proj-..." \
  -H "Content-Type: multipart/form-data" \
  -F file="@audio.mp3" \
  -F model="whisper-1" \
  -F response_format="verbose_json"
```

**Response**:
```json
{
  "text": "Hello, I need help with my account.",
  "language": "en",
  "duration": 3.5,
  "segments": [
    {
      "id": 0,
      "start": 0.0,
      "end": 3.5,
      "text": "Hello, I need help with my account.",
      "tokens": [50364, 50414, ...],
      "temperature": 0.0,
      "avg_logprob": -0.18,
      "compression_ratio": 1.2,
      "no_speech_prob": 0.02
    }
  ]
}
```

### B. Integration Configuration Examples

#### OpenAI Integration via UI
1. Navigate to Settings → Integrations
2. Click "OpenAI" card
3. Enter API key: `sk-proj-...`
4. Check "Enable audio transcription"
5. Check "Detect and store audio language"
6. Save

#### Programmatic Configuration
```ruby
# Via Rails console
account = Account.find(123)

hook = account.hooks.create!(
  app_id: 'openai',
  status: 'enabled',
  settings: {
    api_key: 'sk-proj-...',
    audio_transcription: true,
    language_detection: true,
    label_suggestion: false
  }
)
```

### C. Message Metadata Structure

#### Example Message with Transcription Metadata
```json
{
  "id": 12345,
  "content": "Original text message\n\nHello, I need help with my account.",
  "message_type": "incoming",
  "content_type": "text",
  "attachments": [
    {
      "id": 67890,
      "file_type": "audio",
      "file_url": "https://...",
      "file_size": 102400
    }
  ],
  "additional_attributes": {
    "transcription": {
      "language": "en",
      "duration": 3.5,
      "transcribed_at": "2025-01-04T15:30:00Z",
      "api_key_source": "integration"
    }
  }
}
```

### D. Troubleshooting Guide

#### Issue: Transcriptions Not Appearing

**Symptoms**: Audio messages created but no transcription added

**Diagnosis Steps**:
1. Check feature flag: `ENV['AUDIO_TRANSCRIPTION_ENABLED']`
2. Check API key available:
   ```ruby
   account = Account.find(...)
   service = Openai::AudioTranscriptionService.new('dummy', account: account)
   service.send(:resolve_api_key)
   ```
3. Check Sidekiq queue:
   ```bash
   bundle exec rails runner "puts Sidekiq::Queue.new.size"
   ```
4. Check job failures:
   ```bash
   bundle exec rails runner "puts Sidekiq::DeadSet.new.size"
   ```

**Solutions**:
- Ensure `AUDIO_TRANSCRIPTION_ENABLED=true`
- Configure integration or set `OPENAI_API_KEY`
- Check Sidekiq is running: `ps aux | grep sidekiq`
- Review failed jobs in Sidekiq UI: `/sidekiq`

#### Issue: High Failure Rate

**Symptoms**: Many transcription jobs failing

**Diagnosis**:
```ruby
# Check failed jobs
Sidekiq::DeadSet.new.each do |job|
  puts job.item['error_message'] if job.item['class'] == 'TranscribeAudioMessageJob'
end
```

**Common Causes**:
- Rate limiting (429 errors) → Upgrade OpenAI tier
- Invalid files (400 errors) → Validate audio format
- Network timeouts → Increase timeout or check connectivity
- Authentication errors (401) → Verify API key valid

#### Issue: Slow Transcription

**Symptoms**: Transcriptions taking >60 seconds

**Diagnosis**:
- Check OpenAI status: https://status.openai.com
- Monitor Sidekiq queue depth
- Check audio file sizes

**Solutions**:
- Scale Sidekiq workers: `SIDEKIQ_CONCURRENCY=50`
- Upgrade OpenAI tier for better throughput
- Implement file size warnings

### E. Cost Estimation Tool

```ruby
# lib/tasks/transcription_cost.rake
namespace :transcription do
  desc 'Estimate monthly transcription costs'
  task estimate_cost: :environment do
    days = 30
    start_date = days.days.ago

    audio_messages = Message.joins(:attachments)
      .where(attachments: { file_type: 'audio' })
      .where('messages.created_at >= ?', start_date)

    total_duration = 0
    audio_messages.find_each do |msg|
      msg.attachments.where(file_type: 'audio').each do |att|
        # Duration stored in metadata or estimate from file size
        duration = att.metadata['duration'] || (att.file_size / 16000.0) # rough estimate
        total_duration += duration
      end
    end

    cost_per_minute = 0.006
    total_minutes = total_duration / 60.0
    estimated_cost = total_minutes * cost_per_minute
    monthly_cost = (estimated_cost / days) * 30

    puts "=" * 50
    puts "Transcription Cost Estimate (#{days} days)"
    puts "=" * 50
    puts "Total audio messages: #{audio_messages.count}"
    puts "Total duration: #{total_minutes.round(2)} minutes"
    puts "Estimated cost: $#{estimated_cost.round(2)}"
    puts "Monthly projection: $#{monthly_cost.round(2)}"
    puts "=" * 50
  end
end
```

---

## Change Log

### Version 2.0 (This Enhancement) - Target: Q1 2025
- **Multi-Channel Support**: Transcription for all channels via listener pattern
- **Background Processing**: Async jobs with ActionCable real-time updates
- **Integration API Keys**: Per-account configuration with ENV fallback
- **Language Detection**: Automatic language detection and metadata storage
- **Retry Logic**: Exponential backoff for transient failures
- **Enhanced Error Handling**: Custom exceptions and proper categorization

### Version 1.0 (Initial Release) - Jan 2025
- **Commit**: 11d2bc818
- **Scope**: API messages controller only
- **Processing**: Synchronous during message creation
- **Configuration**: `ENV['OPENAI_API_KEY']` only
- **Features**: Basic transcription with OpenAI Whisper-1

---

## Contributors and Acknowledgments

**Story Author**: Claude (Anthropic)
**Technical Review**: [Engineering Team]
**Product Owner**: [Product Manager]
**Stakeholders**: Engineering, Product, Support, DevOps

**References**:
- Original Feature: `/docs/features/FEAT-003/README.md`
- OpenAI Whisper API: https://platform.openai.com/docs/api-reference/audio
- Rails Event Dispatcher: https://guides.rubyonrails.org/active_support_instrumentation.html
- Sidekiq Retry Logic: https://github.com/sidekiq/sidekiq/wiki/Error-Handling

---

**Document Version**: 1.0
**Last Updated**: 2025-01-04
**Next Review**: After Phase 1 completion
