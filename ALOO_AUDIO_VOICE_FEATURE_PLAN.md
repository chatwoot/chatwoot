# Aloo AI Audio Transcription & Voice Reply Feature Plan

## Overview

This document outlines the implementation plan for adding audio transcription (speech-to-text) and ElevenLabs voice reply (text-to-speech) capabilities to Aloo AI.

**Goals:**
1. Enable Aloo AI to understand voice messages/notes from WhatsApp and other channels
2. Enable Aloo AI to respond with voice messages using ElevenLabs text-to-speech

---

## Current Architecture Analysis

### Existing Components

| Component | Location | Purpose |
|-----------|----------|---------|
| `Aloo::ResponseJob` | `app/jobs/aloo/response_job.rb` | Local RubyLLM-based AI responses |
| `RequestAiResponseJob` | `app/jobs/request_ai_response_job.rb` | External ALOOSTUDIO backend (has audio support) |
| `Message#content_for_llm` | `app/models/message.rb:262-273` | Returns message content with transcription fallback |
| `AlooAgentListener` | `app/listeners/aloo_agent_listener.rb` | Triggers AI responses on message creation |
| `Aloo::Assistant` | `app/models/aloo/assistant.rb` | Assistant configuration (personality, model, etc.) |
| `Attachment` | `app/models/attachment.rb` | Handles file attachments with `meta['transcribed_text']` support |

### Current Audio Flow (RequestAiResponseJob - External)
```
Voice Message → WhatsApp Webhook → Attachment Created → RequestAiResponseJob
                                                              ↓
                                   Sends audio to ALOOSTUDIO backend → Transcription + AI Response
                                                              ↓
                                   Returns transcribed_text + response + optional audio
```

### Current Aloo Local Flow (No Audio Support Yet)
```
Text Message → AlooAgentListener → Aloo::ResponseJob → ConversationAgent → Text Response
```

**Note:** We will build all audio/voice functionality from scratch within the `app/` directory (not using enterprise/). The transcription and voice synthesis will be part of the Aloo module.

---

## Proposed Architecture

### Audio Input Flow (Speech-to-Text)
```
Voice Message → WhatsApp Webhook
       ↓
Attachment Created (file_type: audio)
       ↓
Aloo::AudioTranscriptionJob (NEW)
       ↓
Aloo::AudioTranscriptionService (NEW - uses OpenAI Whisper)
       ↓
Store transcription in attachment.meta['transcribed_text']
       ↓
AlooAgentListener detects audio message with transcription
       ↓
Aloo::ResponseJob (uses Message#content_for_llm)
       ↓
ConversationAgent generates text response
```

### Voice Output Flow (Text-to-Speech with ElevenLabs)
```
AI Text Response Generated
       ↓
Check if voice_reply_enabled on Aloo::Assistant
       ↓
Aloo::VoiceSynthesisService (NEW - ElevenLabs API)
       ↓
Create audio attachment from synthesized audio
       ↓
Send voice message via channel (WhatsApp, etc.)
```

---

## Implementation Plan

### Phase 1: Audio Transcription for Aloo AI

#### 1.1 Database Migration
Create migration for assistant voice settings:

```ruby
# db/migrate/XXXXXX_add_voice_settings_to_aloo_assistants.rb
class AddVoiceSettingsToAlooAssistants < ActiveRecord::Migration[7.0]
  def change
    add_column :aloo_assistants, :voice_enabled, :boolean, default: false
    add_column :aloo_assistants, :voice_input_enabled, :boolean, default: false
    add_column :aloo_assistants, :voice_output_enabled, :boolean, default: false
    add_column :aloo_assistants, :voice_config, :jsonb, default: {}
    # voice_config schema:
    # {
    #   "transcription_provider": "openai",  # openai, google, deepgram
    #   "transcription_model": "whisper-1",
    #   "tts_provider": "elevenlabs",
    #   "elevenlabs_voice_id": "xxx",
    #   "elevenlabs_model_id": "eleven_multilingual_v2",
    #   "elevenlabs_stability": 0.5,
    #   "elevenlabs_similarity_boost": 0.75,
    #   "reply_mode": "text_and_voice"  # text_only, voice_only, text_and_voice
    # }

    # Add indexes for common queries
    add_index :aloo_assistants, :voice_enabled
    add_index :aloo_assistants, :voice_input_enabled
    add_index :aloo_assistants, :voice_output_enabled
  end
end
```

#### 1.1b Voice Usage Tracking Migration
Track ElevenLabs character usage for billing and cost management:

```ruby
# db/migrate/XXXXXX_create_aloo_voice_usage_records.rb
class CreateAlooVoiceUsageRecords < ActiveRecord::Migration[7.0]
  def change
    create_table :aloo_voice_usage_records do |t|
      t.references :account, null: false, foreign_key: true
      t.references :aloo_assistant, null: false, foreign_key: true
      t.references :message, null: true, foreign_key: true
      t.string :operation_type, null: false  # 'transcription' or 'synthesis'
      t.string :provider, null: false        # 'openai', 'elevenlabs'
      t.integer :characters_used, default: 0
      t.integer :audio_duration_seconds, default: 0
      t.decimal :estimated_cost, precision: 10, scale: 6
      t.string :model_used
      t.string :voice_id
      t.string :status, default: 'success'   # 'success', 'failed'
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :aloo_voice_usage_records, [:account_id, :created_at]
    add_index :aloo_voice_usage_records, [:account_id, :operation_type]
    add_index :aloo_voice_usage_records, :created_at
  end
end
```

#### 1.1c Voice Config Model Validation
Add validation for voice_config JSONB in the Assistant model:

```ruby
# app/models/aloo/assistant.rb (additions)
class Aloo::Assistant < ApplicationRecord
  VALID_REPLY_MODES = %w[text_only voice_only text_and_voice].freeze
  VALID_TTS_PROVIDERS = %w[elevenlabs].freeze
  VALID_TRANSCRIPTION_PROVIDERS = %w[openai].freeze

  validate :validate_voice_config

  # Convenience accessors for voice_config
  store_accessor :voice_config,
                 :transcription_provider,
                 :transcription_model,
                 :tts_provider,
                 :elevenlabs_voice_id,
                 :elevenlabs_model_id,
                 :elevenlabs_stability,
                 :elevenlabs_similarity_boost,
                 :reply_mode

  private

  def validate_voice_config
    return unless voice_enabled?

    if voice_output_enabled?
      errors.add(:voice_config, 'elevenlabs_voice_id is required') if elevenlabs_voice_id.blank?
      errors.add(:voice_config, 'invalid reply_mode') unless VALID_REPLY_MODES.include?(reply_mode)
    end

    if voice_input_enabled?
      errors.add(:voice_config, 'invalid transcription_provider') if transcription_provider.present? &&
                                                                     !VALID_TRANSCRIPTION_PROVIDERS.include?(transcription_provider)
    end
  end
end
```

#### 1.2 Add ElevenLabs API Key Configuration
```ruby
# Add to installation_config or account settings
# ELEVENLABS_API_KEY - stored securely
```

#### 1.3 Create Audio Transcription Service for Aloo (Using RubyLLM)

RubyLLM v1.9.0+ provides built-in audio transcription via `RubyLLM.transcribe()`. This eliminates the need for a custom OpenAI client.

**RubyLLM Transcription Features:**
- Models: `whisper-1` (default), `gpt-4o-transcribe`, `gpt-4o-mini-transcribe`, Gemini models
- Language hints: ISO 639-1 codes (en, ar, es, fr, etc.)
- File formats: MP3, M4A, WAV, WebM, OGG
- File size limit: 25 MB
- Optional: Speaker diarization with `gpt-4o-transcribe-diarize`

```ruby
# app/services/aloo/audio_transcription_service.rb
module Aloo
  class AudioTranscriptionService
    DEFAULT_MODEL = 'whisper-1'.freeze
    MAX_FILE_SIZE = 25.megabytes

    attr_reader :attachment, :message, :assistant

    def initialize(attachment)
      @attachment = attachment
      @message = attachment.message
      @assistant = message&.inbox&.aloo_assistant
    end

    def perform
      return { error: 'No assistant configured' } unless assistant&.voice_input_enabled?
      return { success: true, transcription: cached_transcription } if cached_transcription.present?
      return { error: 'File too large' } if attachment.file.byte_size > MAX_FILE_SIZE

      transcription = transcribe_audio
      store_transcription(transcription)
      notify_message_updated

      { success: true, transcription: transcription }
    rescue RubyLLM::Error => e
      Rails.logger.error("[Aloo::AudioTranscription] RubyLLM error: #{e.message}")
      { error: e.message }
    end

    private

    def transcribe_audio
      temp_file = download_to_tempfile

      result = RubyLLM.transcribe(
        temp_file.path,
        model: transcription_model,
        language: language_hint
      )

      result.text
    ensure
      temp_file&.close
      temp_file&.unlink
    end

    def download_to_tempfile
      temp_file = Tempfile.new(['audio', File.extname(attachment.file.filename.to_s)])
      temp_file.binmode
      attachment.file.blob.open do |blob_file|
        IO.copy_stream(blob_file, temp_file)
      end
      temp_file.rewind
      temp_file
    end

    def transcription_model
      assistant.voice_config&.dig('transcription_model') || DEFAULT_MODEL
    end

    def language_hint
      # Map assistant language to ISO 639-1 code
      assistant.language == 'ar' ? 'ar' : assistant.language
    end

    def store_transcription(text)
      return if text.blank?

      meta = attachment.meta || {}
      meta['transcribed_text'] = text
      attachment.update!(meta: meta)
    end

    def cached_transcription
      attachment.meta&.dig('transcribed_text')
    end

    def notify_message_updated
      message.reload.send_update_event
    end
  end
end
```

**Usage Example:**
```ruby
# Basic transcription
result = Aloo::AudioTranscriptionService.new(attachment).perform
# => { success: true, transcription: "Hello, how can I help you?" }

# The transcription is stored in attachment.meta['transcribed_text']
# and can be retrieved via Message#content_for_llm
```

#### 1.4 Create Audio Transcription Job
```ruby
# app/jobs/aloo/audio_transcription_job.rb
module Aloo
  class AudioTranscriptionJob < ApplicationJob
    queue_as :default
    retry_on StandardError, wait: :polynomially_longer, attempts: 3

    def perform(attachment_id, trigger_response: true)
      attachment = Attachment.find_by(id: attachment_id)
      return if attachment.blank?

      result = Aloo::AudioTranscriptionService.new(attachment).perform
      return unless result[:success] && trigger_response

      # Trigger AI response after successful transcription
      message = attachment.message
      conversation = message.conversation
      Aloo::ResponseJob.perform_later(conversation.id, message.id)
    end
  end
end
```

#### 1.5 Modify AlooAgentListener
```ruby
# Changes to app/listeners/aloo_agent_listener.rb
#
# Current: Only responds to text messages (content.present?)
# New: Also handle audio messages
#
# def message_created(event)
#   message, account = extract_message_and_account(event)
#
#   # Check for audio attachments first
#   audio_attachment = message.attachments.find { |a| a.file_type == 'audio' }
#   if audio_attachment.present?
#     # Trigger transcription job (which will chain to ResponseJob)
#     Aloo::AudioTranscriptionJob.perform_later(audio_attachment.id)
#     return
#   end
#
#   return unless should_respond_to_message?(message)
#   Aloo::ResponseJob.perform_later(message.conversation_id, message.id)
# end
```

#### 1.6 Modify Aloo::ResponseJob
- Use `Message#content_for_llm` which already handles transcription fallback
- The method returns `"[Voice Message] #{transcription}"` for audio messages

---

### Phase 2: ElevenLabs Voice Reply Integration

#### 2.1 Create ElevenLabs API Client
```ruby
# app/services/aloo/elevenlabs_client.rb
module Aloo
  class ElevenlabsClient
    BASE_URL = 'https://api.elevenlabs.io/v1'

    def initialize(api_key:)
    end

    def text_to_speech(text:, voice_id:, model_id:, options: {})
      # POST /v1/text-to-speech/{voice_id}
      # Returns audio binary (mp3)
    end

    def list_voices
      # GET /v1/voices
    end

    def get_voice(voice_id)
      # GET /v1/voices/{voice_id}
    end
  end
end
```

#### 2.2 Create Voice Synthesis Service
```ruby
# app/services/aloo/voice_synthesis_service.rb
module Aloo
  class VoiceSynthesisService
    # Input: text response, assistant voice config
    # Output: audio file (temp file or binary)
    # Uses ElevenlabsClient for TTS
    # Handles language/dialect mapping to voice selection
  end
end
```

#### 2.2b Create Audio Format Conversion Service
WhatsApp requires OGG/Opus format, but ElevenLabs returns MP3. This service handles conversion:

```ruby
# app/services/aloo/audio_conversion_service.rb
module Aloo
  class AudioConversionService
    SUPPORTED_OUTPUT_FORMATS = %w[ogg mp3 wav].freeze
    WHATSAPP_FORMAT = 'ogg'.freeze
    FFMPEG_TIMEOUT = 30.seconds

    class ConversionError < StandardError; end

    attr_reader :input_path, :output_format

    def initialize(input_path, output_format: WHATSAPP_FORMAT)
      @input_path = input_path
      @output_format = output_format
      validate_format!
    end

    def convert
      output_path = generate_output_path
      execute_ffmpeg(output_path)
      output_path
    rescue StandardError => e
      Rails.logger.error("[Aloo::AudioConversion] Failed: #{e.message}")
      raise ConversionError, "Audio conversion failed: #{e.message}"
    end

    def self.convert_to_whatsapp(input_path)
      new(input_path, output_format: WHATSAPP_FORMAT).convert
    end

    private

    def validate_format!
      return if SUPPORTED_OUTPUT_FORMATS.include?(output_format)

      raise ArgumentError, "Unsupported format: #{output_format}"
    end

    def generate_output_path
      dir = File.dirname(input_path)
      basename = File.basename(input_path, '.*')
      File.join(dir, "#{basename}_converted.#{output_format}")
    end

    def execute_ffmpeg(output_path)
      command = build_ffmpeg_command(output_path)

      Timeout.timeout(FFMPEG_TIMEOUT) do
        success = system(*command)
        raise ConversionError, 'FFmpeg command failed' unless success
      end
    end

    def build_ffmpeg_command(output_path)
      base_cmd = ['ffmpeg', '-y', '-i', input_path]

      case output_format
      when 'ogg'
        # Opus codec for WhatsApp voice notes
        base_cmd + ['-c:a', 'libopus', '-b:a', '64k', '-vbr', 'on', output_path]
      when 'mp3'
        base_cmd + ['-c:a', 'libmp3lame', '-b:a', '128k', output_path]
      when 'wav'
        base_cmd + ['-c:a', 'pcm_s16le', output_path]
      end
    end
  end
end
```

**Usage in VoiceSynthesisService:**
```ruby
# After getting MP3 from ElevenLabs, convert for WhatsApp
mp3_path = elevenlabs_client.text_to_speech(...)
ogg_path = Aloo::AudioConversionService.convert_to_whatsapp(mp3_path)
```

#### 2.3 Create Voice Reply Job
```ruby
# app/jobs/aloo/voice_reply_job.rb
module Aloo
  class VoiceReplyJob < ApplicationJob
    # Input: message_id (the text response message)
    # Process:
    #   1. Get assistant voice config
    #   2. Call VoiceSynthesisService
    #   3. Create audio attachment on message
    #   4. Send via channel (WhatsApp voice note)
  end
end
```

#### 2.4 Modify Aloo::ResponseJob
- After sending text response, check `voice_output_enabled`
- Queue VoiceReplyJob if enabled
- Handle `reply_mode` (text_only, voice_only, text_and_voice)

#### 2.5 Create Voice Message Sender
```ruby
# app/services/aloo/voice_message_sender_service.rb
module Aloo
  class VoiceMessageSenderService
    # Channel-specific logic for sending voice messages
    # WhatsApp: uses audio/ogg with proper content type
    # Other channels: appropriate format
  end
end
```

#### 2.6 Temporary File Cleanup Job
Clean up orphaned temporary audio files from failed jobs:

```ruby
# app/jobs/aloo/temp_file_cleanup_job.rb
module Aloo
  class TempFileCleanupJob < ApplicationJob
    queue_as :low

    # Run daily via cron/whenever
    def perform
      cleanup_stale_temp_files
      log_cleanup_stats
    end

    private

    def cleanup_stale_temp_files
      temp_dir = Rails.root.join('tmp', 'aloo_audio')
      return unless Dir.exist?(temp_dir)

      stale_threshold = 1.hour.ago
      deleted_count = 0

      Dir.glob(File.join(temp_dir, '*')).each do |file|
        next unless File.file?(file)
        next unless File.mtime(file) < stale_threshold

        File.delete(file)
        deleted_count += 1
      rescue Errno::ENOENT
        # File already deleted, skip
      end

      @deleted_count = deleted_count
    end

    def log_cleanup_stats
      Aloo::VoiceLogger.log(:temp_files_cleaned, { count: @deleted_count })
    end
  end
end
```

**Schedule with whenever/sidekiq-cron:**
```ruby
# config/schedule.rb (whenever)
every 1.day, at: '3:00 am' do
  runner 'Aloo::TempFileCleanupJob.perform_later'
end

# OR config/sidekiq_cron.yml
aloo_temp_cleanup:
  cron: '0 3 * * *'
  class: Aloo::TempFileCleanupJob
```

---

### Phase 3: Admin UI Configuration

#### 3.1 Voice Settings Tab in Assistant Configuration
```vue
<!-- app/javascript/dashboard/routes/dashboard/settings/aloo/components/VoiceSettings.vue -->
- Toggle: Enable Voice Features
- Toggle: Voice Input (transcription)
- Toggle: Voice Output (TTS)
- Dropdown: TTS Provider (ElevenLabs)
- Dropdown: Voice Selection (from ElevenLabs API)
- Slider: Stability (0-1)
- Slider: Similarity Boost (0-1)
- Radio: Reply Mode (text_only, voice_only, text_and_voice)
- Test Button: Generate sample audio
```

#### 3.2 API Endpoints for Voice Configuration

```ruby
# config/routes.rb (additions)
namespace :api do
  namespace :v1 do
    namespace :accounts do
      resources :aloo_assistants do
        member do
          get :voices           # List available ElevenLabs voices
          post :preview_voice   # Generate sample audio with selected voice
        end
      end
    end

    namespace :conversations do
      namespace :messages do
        resources :attachments do
          member do
            post :retranscribe  # Re-run transcription on audio attachment
          end
        end
      end
    end
  end
end
```

```ruby
# app/controllers/api/v1/accounts/aloo_assistants_controller.rb (additions)
module Api::V1::Accounts
  class AlooAssistantsController < BaseController
    # ... existing code ...

    # GET /api/v1/accounts/:account_id/aloo_assistants/:id/voices
    def voices
      client = Aloo::ElevenlabsClient.new(api_key: elevenlabs_api_key)
      voices = client.list_voices

      render json: {
        voices: voices.map { |v| { id: v['voice_id'], name: v['name'], preview_url: v['preview_url'] } }
      }
    rescue Aloo::ElevenlabsClient::Error => e
      render json: { error: e.message }, status: :service_unavailable
    end

    # POST /api/v1/accounts/:account_id/aloo_assistants/:id/preview_voice
    def preview_voice
      text = params[:text] || 'Hello, this is a voice preview.'
      voice_id = params[:voice_id]

      service = Aloo::VoiceSynthesisService.new(
        text: text,
        assistant: @assistant,
        voice_id_override: voice_id
      )
      result = service.perform

      if result[:success]
        send_data result[:audio_data],
                  type: 'audio/mpeg',
                  disposition: 'inline',
                  filename: 'preview.mp3'
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    private

    def assistant_params
      params.require(:aloo_assistant).permit(
        :name, :personality, :model, :language,
        :voice_enabled, :voice_input_enabled, :voice_output_enabled,
        voice_config: [
          :transcription_provider, :transcription_model,
          :tts_provider, :elevenlabs_voice_id, :elevenlabs_model_id,
          :elevenlabs_stability, :elevenlabs_similarity_boost, :reply_mode
        ]
      )
    end

    def elevenlabs_api_key
      # Fetch from account settings or installation config
      Current.account.custom_attributes&.dig('elevenlabs_api_key') ||
        InstallationConfig.find_by(name: 'ELEVENLABS_API_KEY')&.value
    end
  end
end
```

#### 3.3 Voice Usage API Endpoints

```ruby
# GET /api/v1/accounts/:account_id/aloo/voice_usage
# Returns usage statistics for the current billing period

module Api::V1::Accounts::Aloo
  class VoiceUsageController < Api::V1::Accounts::BaseController
    def index
      period_start = params[:period_start]&.to_date || Time.current.beginning_of_month
      period_end = params[:period_end]&.to_date || Time.current.end_of_month

      usage = Aloo::VoiceUsageRecord
              .where(account: Current.account)
              .where(created_at: period_start..period_end)

      render json: {
        period: { start: period_start, end: period_end },
        transcription: {
          count: usage.where(operation_type: 'transcription').count,
          total_duration_seconds: usage.where(operation_type: 'transcription').sum(:audio_duration_seconds),
          estimated_cost: usage.where(operation_type: 'transcription').sum(:estimated_cost)
        },
        synthesis: {
          count: usage.where(operation_type: 'synthesis').count,
          total_characters: usage.where(operation_type: 'synthesis').sum(:characters_used),
          estimated_cost: usage.where(operation_type: 'synthesis').sum(:estimated_cost)
        },
        total_estimated_cost: usage.sum(:estimated_cost),
        daily_breakdown: daily_breakdown(usage)
      }
    end

    private

    def daily_breakdown(usage)
      usage.group("DATE(created_at)")
           .select("DATE(created_at) as date, operation_type, COUNT(*) as count, SUM(characters_used) as characters")
           .group(:operation_type)
           .map { |r| { date: r.date, type: r.operation_type, count: r.count, characters: r.characters } }
    end
  end
end
```

---

## File Structure

```
app/
├── controllers/
│   └── api/
│       └── v1/
│           └── accounts/
│               ├── aloo_assistants_controller.rb  # MODIFY - Add voice endpoints
│               └── aloo/
│                   └── voice_usage_controller.rb  # NEW - Usage statistics API
│               └── conversations/
│                   └── messages/
│                       └── attachments_controller.rb # NEW - Retranscribe endpoint
├── jobs/
│   └── aloo/
│       ├── audio_transcription_job.rb    # NEW - Async transcription (with idempotency)
│       ├── voice_reply_job.rb            # NEW - Async TTS generation
│       └── temp_file_cleanup_job.rb      # NEW - Periodic cleanup of orphaned temp files
├── services/
│   └── aloo/
│       ├── audio_transcription_service.rb # NEW - Uses RubyLLM.transcribe()
│       ├── audio_conversion_service.rb    # NEW - FFmpeg-based format conversion
│       ├── audio_input_validator.rb       # NEW - Validates audio attachments
│       ├── elevenlabs_client.rb           # NEW - ElevenLabs API wrapper
│       ├── voice_synthesis_service.rb     # NEW - TTS orchestration
│       ├── voice_message_sender_service.rb # NEW - Channel-specific voice sending
│       ├── voice_rate_limiter.rb          # NEW - Per-account rate limiting
│       ├── api_circuit_breaker.rb         # NEW - Circuit breaker for external APIs
│       ├── voice_logger.rb                # NEW - Structured logging
│       ├── voice_metrics.rb               # NEW - StatsD metrics
│       └── text_sanitizer.rb              # NEW - Sanitize text for TTS
├── models/
│   └── aloo/
│       ├── assistant.rb                   # MODIFY - Add voice config accessors & validation
│       └── voice_usage_record.rb          # NEW - Usage tracking model
├── listeners/
│   └── aloo_agent_listener.rb             # MODIFY - Add audio message handling
└── javascript/
    └── dashboard/
        └── routes/dashboard/settings/aloo/
            └── components/
                ├── VoiceSettings.vue      # NEW - Voice configuration UI
                └── VoicePreview.vue       # NEW - Voice preview player

db/
└── migrate/
    ├── XXXXXX_add_voice_settings_to_aloo_assistants.rb  # NEW
    └── XXXXXX_create_aloo_voice_usage_records.rb        # NEW

config/
├── initializers/
│   └── aloo_voice.rb                      # NEW - RubyLLM version check, defaults
├── locales/
│   └── en.yml                             # MODIFY (add voice i18n keys)
└── routes.rb                              # MODIFY (add voice API routes)
```

**All new code will be created in `app/` directory - no enterprise/ dependencies.**
**Audio transcription uses RubyLLM built-in `RubyLLM.transcribe()` - no custom OpenAI client needed.**

---

## API Integrations

### RubyLLM Audio Transcription (Speech-to-Text)
RubyLLM v1.9.0+ provides built-in transcription via `RubyLLM.transcribe()`.

**Available Models:**
| Model | Provider | Features |
|-------|----------|----------|
| `whisper-1` | OpenAI | Default, fast, accurate |
| `gpt-4o-transcribe` | OpenAI | Higher accuracy |
| `gpt-4o-mini-transcribe` | OpenAI | Faster, lower cost |
| `gpt-4o-transcribe-diarize` | OpenAI | Speaker identification |
| Gemini models | Google | Alternative provider |

**Supported Audio Formats:** MP3, M4A, WAV, WebM, OGG
**File Size Limit:** 25 MB
**Languages:** Auto-detect or ISO 639-1 hint (en, ar, es, fr, de, etc.)

**Code Example:**
```ruby
# Basic transcription
result = RubyLLM.transcribe("audio.ogg")
result.text  # => "Hello, how can I help you?"

# With language hint for Arabic
result = RubyLLM.transcribe("audio.ogg", language: "ar")

# With specific model
result = RubyLLM.transcribe("audio.ogg", model: "gpt-4o-transcribe")
```

### ElevenLabs (Text-to-Speech)
- API Base: `https://api.elevenlabs.io/v1`
- Authentication: `xi-api-key` header
- Key Endpoints:
  - `POST /v1/text-to-speech/{voice_id}` - Generate audio
  - `GET /v1/voices` - List available voices
  - `GET /v1/user` - Get subscription info (for rate limiting)

**Request Example:**
```bash
POST https://api.elevenlabs.io/v1/text-to-speech/{voice_id}
Headers:
  xi-api-key: {API_KEY}
  Content-Type: application/json
Body:
{
  "text": "Hello, how can I help you today?",
  "model_id": "eleven_multilingual_v2",
  "voice_settings": {
    "stability": 0.5,
    "similarity_boost": 0.75
  }
}
Response: audio/mpeg binary
```

**Popular Multilingual Voices:**
- `EXAVITQu4vr4xnSDxMaL` - Sarah (neutral)
- `TX3LPaxmHKxFdv7VOQHJ` - Liam (British)
- `pqHfZKP75CvOlQylNhV4` - Bill (American)
- Arabic voices available through voice cloning or custom voices

---

## Configuration & Environment Variables

```env
# Required for voice features
ELEVENLABS_API_KEY=your_elevenlabs_api_key

# Optional (defaults shown)
ELEVENLABS_DEFAULT_VOICE_ID=EXAVITQu4vr4xnSDxMaL
ELEVENLABS_DEFAULT_MODEL=eleven_multilingual_v2
```

---

## Security Considerations

1. **API Key Storage**: ElevenLabs API key should be stored encrypted (like other provider keys)
2. **Rate Limiting**: ElevenLabs has character limits per tier - implement rate limiting
3. **Audio File Handling**: Temporary files should be cleaned up after processing
4. **Content Validation**: Sanitize text before sending to TTS (remove potential injection)

---

## Concurrency & Idempotency

### Job Idempotency
Prevent duplicate processing of the same attachment:

```ruby
# app/jobs/aloo/audio_transcription_job.rb
module Aloo
  class AudioTranscriptionJob < ApplicationJob
    queue_as :default
    retry_on StandardError, wait: :polynomially_longer, attempts: 3

    # Prevent duplicate jobs for the same attachment
    unique :until_executed, on_conflict: :log

    def perform(attachment_id, trigger_response: true)
      attachment = Attachment.find_by(id: attachment_id)
      return if attachment.blank?

      # Check if already processed (idempotency check)
      return if attachment.meta&.dig('transcription_status') == 'completed'

      # Mark as processing to prevent concurrent execution
      return unless claim_transcription_lock(attachment)

      begin
        update_transcription_status(attachment, 'processing')
        result = Aloo::AudioTranscriptionService.new(attachment).perform

        if result[:success]
          update_transcription_status(attachment, 'completed')
          trigger_ai_response(attachment) if trigger_response
        else
          update_transcription_status(attachment, 'failed', result[:error])
        end
      rescue StandardError => e
        update_transcription_status(attachment, 'failed', e.message)
        raise
      end
    end

    private

    def claim_transcription_lock(attachment)
      # Atomic update to prevent race conditions
      updated = Attachment.where(id: attachment.id)
                          .where("meta->>'transcription_status' IS NULL OR meta->>'transcription_status' = 'pending'")
                          .update_all("meta = jsonb_set(COALESCE(meta, '{}'), '{transcription_status}', '\"processing\"')")
      updated > 0
    end

    def update_transcription_status(attachment, status, error = nil)
      meta = attachment.meta || {}
      meta['transcription_status'] = status
      meta['transcription_error'] = error if error
      meta['transcription_updated_at'] = Time.current.iso8601
      attachment.update!(meta: meta)
    end

    def trigger_ai_response(attachment)
      message = attachment.message
      Aloo::ResponseJob.perform_later(message.conversation_id, message.id)
    end
  end
end
```

### Transcription Status States
```
pending → processing → completed
                    ↘ failed
```

Status stored in `attachment.meta['transcription_status']`:
- `pending` - Queued for transcription
- `processing` - Currently being transcribed
- `completed` - Successfully transcribed
- `failed` - Transcription failed (see `transcription_error`)

---

## Rate Limiting & Circuit Breaker

### ElevenLabs Rate Limiting
Implement per-account rate limiting to prevent exceeding ElevenLabs quotas:

```ruby
# app/services/aloo/voice_rate_limiter.rb
module Aloo
  class VoiceRateLimiter
    DAILY_CHARACTER_LIMIT = 100_000  # Configurable per account
    HOURLY_REQUEST_LIMIT = 100

    class RateLimitExceeded < StandardError; end

    def initialize(account)
      @account = account
    end

    def check_and_increment!(characters:)
      raise RateLimitExceeded, 'Daily character limit exceeded' if daily_limit_exceeded?(characters)
      raise RateLimitExceeded, 'Hourly request limit exceeded' if hourly_limit_exceeded?

      increment_counters(characters)
    end

    def remaining_characters
      limit = account_daily_limit
      used = daily_characters_used
      [limit - used, 0].max
    end

    private

    def daily_limit_exceeded?(characters)
      daily_characters_used + characters > account_daily_limit
    end

    def hourly_limit_exceeded?
      hourly_request_count >= HOURLY_REQUEST_LIMIT
    end

    def daily_characters_used
      Aloo::VoiceUsageRecord
        .where(account: @account, operation_type: 'synthesis')
        .where('created_at > ?', Time.current.beginning_of_day)
        .sum(:characters_used)
    end

    def hourly_request_count
      Aloo::VoiceUsageRecord
        .where(account: @account, operation_type: 'synthesis')
        .where('created_at > ?', 1.hour.ago)
        .count
    end

    def account_daily_limit
      @account.custom_attributes&.dig('voice_daily_character_limit') || DAILY_CHARACTER_LIMIT
    end

    def increment_counters(characters)
      # Usage is recorded by VoiceSynthesisService after successful synthesis
    end
  end
end
```

### Circuit Breaker for External APIs
Prevent cascading failures when ElevenLabs or OpenAI is down:

```ruby
# app/services/aloo/api_circuit_breaker.rb
module Aloo
  class ApiCircuitBreaker
    FAILURE_THRESHOLD = 5
    RESET_TIMEOUT = 60.seconds
    HALF_OPEN_REQUESTS = 3

    class CircuitOpen < StandardError; end

    def initialize(service_name)
      @service_name = service_name
      @redis_key = "circuit_breaker:#{service_name}"
    end

    def call
      check_circuit!

      begin
        result = yield
        record_success
        result
      rescue StandardError => e
        record_failure
        raise
      end
    end

    def open?
      state == 'open' && !timeout_expired?
    end

    def state
      Redis.current.hget(@redis_key, 'state') || 'closed'
    end

    private

    def check_circuit!
      return unless open?

      raise CircuitOpen, "Circuit breaker open for #{@service_name}"
    end

    def record_success
      Redis.current.hdel(@redis_key, 'failures')
      Redis.current.hset(@redis_key, 'state', 'closed') if state == 'half_open'
    end

    def record_failure
      failures = Redis.current.hincrby(@redis_key, 'failures', 1)

      if failures >= FAILURE_THRESHOLD
        Redis.current.hset(@redis_key, 'state', 'open')
        Redis.current.hset(@redis_key, 'opened_at', Time.current.to_i)
      end
    end

    def timeout_expired?
      opened_at = Redis.current.hget(@redis_key, 'opened_at').to_i
      Time.current.to_i - opened_at > RESET_TIMEOUT
    end
  end
end
```

**Usage in ElevenLabs Client:**
```ruby
class ElevenlabsClient
  def text_to_speech(text:, voice_id:, **)
    circuit_breaker.call do
      # Make API request
    end
  end

  private

  def circuit_breaker
    @circuit_breaker ||= Aloo::ApiCircuitBreaker.new('elevenlabs')
  end
end
```

---

## Monitoring & Observability

### Logging Strategy
Structured logging for all voice operations:

```ruby
# app/services/aloo/voice_logger.rb
module Aloo
  class VoiceLogger
    LEVELS = {
      transcription_started: :info,
      transcription_completed: :info,
      transcription_failed: :error,
      synthesis_started: :info,
      synthesis_completed: :info,
      synthesis_failed: :error,
      rate_limit_exceeded: :warn,
      circuit_breaker_opened: :error
    }.freeze

    def self.log(event, context = {})
      level = LEVELS[event] || :info
      message = build_message(event, context)

      Rails.logger.public_send(level, message)

      # Also send to external monitoring (Sentry, DataDog, etc.)
      track_metric(event, context) if respond_to?(:track_metric, true)
    end

    private_class_method def self.build_message(event, context)
      {
        source: 'aloo_voice',
        event: event,
        timestamp: Time.current.iso8601,
        **context
      }.to_json
    end
  end
end
```

**Usage:**
```ruby
Aloo::VoiceLogger.log(:transcription_completed, {
  attachment_id: attachment.id,
  duration_seconds: 15,
  model: 'whisper-1',
  language: 'ar'
})
```

### Metrics Collection
Track key metrics for dashboards and alerting:

```ruby
# app/services/aloo/voice_metrics.rb
module Aloo
  class VoiceMetrics
    class << self
      def track_transcription(account_id:, duration_ms:, success:, model:)
        StatsD.increment('aloo.voice.transcription.count', tags: tags(account_id, success))
        StatsD.histogram('aloo.voice.transcription.duration_ms', duration_ms, tags: tags(account_id, success))
      end

      def track_synthesis(account_id:, characters:, duration_ms:, success:, voice_id:)
        StatsD.increment('aloo.voice.synthesis.count', tags: tags(account_id, success))
        StatsD.histogram('aloo.voice.synthesis.characters', characters, tags: tags(account_id, success))
        StatsD.histogram('aloo.voice.synthesis.duration_ms', duration_ms, tags: tags(account_id, success))
      end

      def track_rate_limit_hit(account_id:)
        StatsD.increment('aloo.voice.rate_limit.exceeded', tags: ["account:#{account_id}"])
      end

      def track_circuit_breaker(service:, state:)
        StatsD.increment('aloo.voice.circuit_breaker.state_change', tags: ["service:#{service}", "state:#{state}"])
      end

      private

      def tags(account_id, success)
        ["account:#{account_id}", "success:#{success}"]
      end
    end
  end
end
```

### Alerting Rules
Configure alerts for critical thresholds:

| Metric | Threshold | Severity | Action |
|--------|-----------|----------|--------|
| `transcription.error_rate` | > 10% over 5 min | High | Page on-call |
| `synthesis.error_rate` | > 10% over 5 min | High | Page on-call |
| `circuit_breaker.opened` | Any | Medium | Notify Slack |
| `rate_limit.exceeded` | > 50/hour per account | Low | Notify account admin |
| `synthesis.characters` | > 80% of daily limit | Low | Notify account admin |

### Dashboard Widgets
Recommended dashboard panels:

1. **Transcription Volume** - Count by hour/day
2. **Synthesis Characters** - Sum by account/day
3. **Error Rate** - Percentage over time
4. **Latency P50/P95/P99** - For both transcription and synthesis
5. **Cost Tracker** - Estimated daily/monthly spend
6. **Top Accounts** - By voice usage

---

## Edge Cases & Error Handling

### Audio Input Edge Cases

| Case | Detection | Handling |
|------|-----------|----------|
| Very short audio (< 0.5s) | Check `audio_duration_seconds` | Skip transcription, log warning |
| Silent audio | Whisper returns empty/whitespace | Store empty, don't trigger AI response |
| Corrupted file | RubyLLM raises error | Mark as failed, notify user |
| Unsupported format | MIME type check | Convert with FFmpeg or reject |
| File too large (> 25MB) | Size check before processing | Reject with user-friendly error |
| Multiple voice messages | Queue ordering | Process sequentially per conversation |

### Voice Output Edge Cases

| Case | Detection | Handling |
|------|-----------|----------|
| Response too long (> 5000 chars) | Character count | Truncate with "[...]" or split into parts |
| Empty response | Blank check | Skip voice synthesis |
| Special characters | Regex detection | Sanitize before TTS |
| Rate limit exceeded | RateLimiter check | Fall back to text-only |
| API timeout | HTTParty timeout | Retry with backoff, then text-only |
| Invalid voice ID | ElevenLabs 404 | Fall back to default voice |

### Implementation

```ruby
# app/services/aloo/audio_input_validator.rb
module Aloo
  class AudioInputValidator
    MIN_DURATION = 0.5.seconds
    MAX_DURATION = 10.minutes
    MAX_FILE_SIZE = 25.megabytes
    SUPPORTED_TYPES = %w[audio/mpeg audio/ogg audio/wav audio/webm audio/mp4 audio/x-m4a].freeze

    ValidationError = Class.new(StandardError)

    def initialize(attachment)
      @attachment = attachment
    end

    def validate!
      validate_file_type!
      validate_file_size!
      validate_duration! if duration_available?

      true
    end

    def valid?
      validate!
    rescue ValidationError
      false
    end

    private

    def validate_file_type!
      return if SUPPORTED_TYPES.include?(@attachment.file.content_type)

      raise ValidationError, "Unsupported audio format: #{@attachment.file.content_type}"
    end

    def validate_file_size!
      return if @attachment.file.byte_size <= MAX_FILE_SIZE

      raise ValidationError, "File too large: #{@attachment.file.byte_size} bytes (max: #{MAX_FILE_SIZE})"
    end

    def validate_duration!
      duration = @attachment.meta&.dig('audio_duration') || 0

      raise ValidationError, 'Audio too short' if duration < MIN_DURATION
      raise ValidationError, 'Audio too long' if duration > MAX_DURATION
    end

    def duration_available?
      @attachment.meta&.dig('audio_duration').present?
    end
  end
end
```

```ruby
# app/services/aloo/text_sanitizer.rb
module Aloo
  class TextSanitizer
    MAX_TTS_LENGTH = 5000
    TRUNCATION_SUFFIX = '...'

    class << self
      def sanitize_for_tts(text)
        text = strip_markdown(text)
        text = remove_urls(text)
        text = normalize_whitespace(text)
        text = truncate_if_needed(text)
        text
      end

      private

      def strip_markdown(text)
        text.gsub(/[*_~`#]/, '')
            .gsub(/\[([^\]]+)\]\([^)]+\)/, '\1')  # [link](url) → link
      end

      def remove_urls(text)
        text.gsub(%r{https?://\S+}, '[link]')
      end

      def normalize_whitespace(text)
        text.gsub(/\s+/, ' ').strip
      end

      def truncate_if_needed(text)
        return text if text.length <= MAX_TTS_LENGTH

        text[0...(MAX_TTS_LENGTH - TRUNCATION_SUFFIX.length)] + TRUNCATION_SUFFIX
      end
    end
  end
end
```

### Retry Transcription Endpoint

```ruby
# POST /api/v1/accounts/:account_id/conversations/:conversation_id/messages/:message_id/attachments/:id/retranscribe
module Api::V1::Accounts::Conversations::Messages
  class AttachmentsController < Api::V1::Accounts::BaseController
    def retranscribe
      @attachment = find_attachment
      authorize @attachment, :update?

      # Reset transcription status
      @attachment.update!(meta: @attachment.meta.merge('transcription_status' => 'pending'))

      # Queue new transcription
      Aloo::AudioTranscriptionJob.perform_later(@attachment.id, trigger_response: false)

      render json: { status: 'queued' }
    end

    private

    def find_attachment
      message = Current.account.conversations
                       .find(params[:conversation_id])
                       .messages.find(params[:message_id])
      message.attachments.find(params[:id])
    end
  end
end
```

---

## Cost Considerations

### OpenAI Whisper
- $0.006 per minute of audio
- Included in existing OpenAI integration

### ElevenLabs
| Tier | Characters/Month | Price |
|------|-----------------|-------|
| Free | 10,000 | $0 |
| Starter | 30,000 | $5/mo |
| Creator | 100,000 | $22/mo |
| Pro | 500,000 | $99/mo |
| Scale | 2,000,000 | $330/mo |

Average response: ~150 characters = ~200 responses/month on Starter tier

---

## Testing Plan

### Unit Tests
- `Aloo::AudioTranscriptionService` - mock OpenAI API
- `Aloo::ElevenlabsClient` - mock ElevenLabs API
- `Aloo::VoiceSynthesisService` - mock client, test file handling
- `Aloo::Assistant` voice config accessors

### Integration Tests
- Full flow: Audio message → Transcription → AI Response → Voice Reply
- AlooAgentListener with audio attachments
- Job chaining (transcription → response → voice)

### E2E Tests
- WhatsApp voice note received → text response + voice reply
- Voice settings UI configuration

---

## Rollout Plan

### Phase 1: Audio Transcription (Week 1-2)
1. Database migration
2. Transcription service and job
3. AlooAgentListener modifications
4. Basic testing with WhatsApp voice notes

### Phase 2: ElevenLabs Integration (Week 2-3)
1. ElevenLabs client implementation
2. Voice synthesis service
3. Voice reply job
4. Integration with response flow

### Phase 3: Admin UI (Week 3-4)
1. Voice settings Vue component
2. API endpoints for voice config
3. Voice selection dropdown
4. Testing and polish

### Phase 4: Production Rollout
1. Feature flag rollout (per-account)
2. Monitoring and cost tracking
3. Documentation

---

## Open Questions for Review

1. **Reply Mode Default**: Should the default be `text_and_voice` or `text_only`?

2. **Voice Selection**: Should we provide pre-configured voice options or allow custom voice IDs?

3. **Arabic Dialect Support**: ElevenLabs multilingual model supports Arabic - should we map dialects to specific voice profiles?

4. **Cost Management**: Should we add per-account limits for voice messages?

5. **Fallback Behavior**: If ElevenLabs fails, should we:
   - Send text only?
   - Retry with exponential backoff?
   - Queue for later?

6. **Audio Format**: WhatsApp prefers opus/ogg - should we convert from mp3 or request different format?

7. **Long Responses**: Should we truncate long responses for voice? Max character limit?

8. **Integration Path**: Should this integrate with:
   - Only `Aloo::ResponseJob` (local RubyLLM)?
   - Also `RequestAiResponseJob` (ALOOSTUDIO)?
   - Both with unified service?

---

## Dependencies

### Ruby Gems
```ruby
# Already available in Gemfile
gem 'ruby_llm'     # v1.9.0+ required for RubyLLM.transcribe()
gem 'down'         # For file downloads (already present)
gem 'marcel'       # For MIME type detection (already present)
gem 'httparty'     # For ElevenLabs API calls (already present)
gem 'redis'        # For circuit breaker state (already present)

# Optional - for better audio handling
gem 'streamio-ffmpeg'  # Ruby wrapper for FFmpeg (optional, can use system FFmpeg)
```

### System Dependencies
```bash
# FFmpeg is required for audio format conversion (MP3 → OGG/Opus)
# Install on macOS:
brew install ffmpeg

# Install on Ubuntu/Debian:
apt-get install ffmpeg

# Install on Alpine (Docker):
apk add ffmpeg

# Verify installation:
ffmpeg -version
```

### Environment Variables
```env
# Already configured (used by RubyLLM for transcription)
OPENAI_API_KEY=xxx          # Required for Whisper models

# New - for ElevenLabs TTS
ELEVENLABS_API_KEY=xxx      # ElevenLabs API key for voice synthesis

# Optional - rate limiting defaults
ALOO_VOICE_DAILY_CHARACTER_LIMIT=100000  # Per-account daily limit
ALOO_VOICE_HOURLY_REQUEST_LIMIT=100      # Per-account hourly limit
```

### RubyLLM Version Check
Ensure RubyLLM v1.9.0+ is installed for transcription support:
```ruby
# Check version
RubyLLM::VERSION  # Should be >= "1.9.0"

# Verify transcription is available
RubyLLM.respond_to?(:transcribe)  # => true
```

### Initializer for Dependency Verification
```ruby
# config/initializers/aloo_voice.rb
Rails.application.config.after_initialize do
  # Check RubyLLM version
  if defined?(RubyLLM) && RubyLLM::VERSION < '1.9.0'
    Rails.logger.warn "[Aloo Voice] RubyLLM #{RubyLLM::VERSION} detected. v1.9.0+ required for transcription."
  end

  # Check FFmpeg availability
  unless system('which ffmpeg > /dev/null 2>&1')
    Rails.logger.warn '[Aloo Voice] FFmpeg not found. Audio format conversion will not work.'
  end

  # Validate ElevenLabs API key if voice output is used
  if ENV['ELEVENLABS_API_KEY'].blank?
    Rails.logger.info '[Aloo Voice] ELEVENLABS_API_KEY not set. Voice synthesis will be disabled.'
  end
end
```

### Node Packages
No additional packages needed.

### Docker Considerations
If running in Docker, ensure FFmpeg is included in the image:
```dockerfile
# Dockerfile additions
RUN apt-get update && apt-get install -y ffmpeg && rm -rf /var/lib/apt/lists/*
```

---

## Approval Checklist

- [ ] Architecture review approved
- [ ] Database schema approved
- [ ] API integration approach approved
- [ ] Cost model accepted
- [ ] Security review completed
- [ ] Open questions resolved

---

**Document Version**: 1.3
**Created**: 2026-01-01
**Updated**: 2026-01-03
**Author**: Aloo AI Development Team
**Status**: AWAITING REVIEW

---

## Changelog

### v1.3 (2026-01-03)
- **Concurrency & Idempotency**: Added job locking mechanism to prevent duplicate transcription processing
- **Transcription Status Tracking**: Added `transcription_status` field to track pending/processing/completed/failed states
- **Usage Tracking**: Added `aloo_voice_usage_records` table for billing and cost management
- **Database Indexes**: Added indexes on voice-related columns for query performance
- **Voice Config Validation**: Added model-level validation and `store_accessor` for voice_config JSONB
- **Audio Format Conversion**: Added `Aloo::AudioConversionService` using FFmpeg for MP3→OGG/Opus conversion
- **Rate Limiting**: Added `Aloo::VoiceRateLimiter` for per-account character/request limits
- **Circuit Breaker**: Added `Aloo::ApiCircuitBreaker` to handle external API failures gracefully
- **Monitoring & Observability**: Added `VoiceLogger` and `VoiceMetrics` for structured logging and StatsD integration
- **Alerting Rules**: Defined thresholds and actions for critical voice metrics
- **Edge Cases**: Added comprehensive handling for audio input/output edge cases
- **Input Validation**: Added `Aloo::AudioInputValidator` for audio file validation
- **Text Sanitization**: Added `Aloo::TextSanitizer` for TTS input sanitization
- **Retry Endpoint**: Added `POST /attachments/:id/retranscribe` for manual re-transcription
- **API Endpoints**: Added voice listing, preview, and usage statistics endpoints
- **File Structure**: Updated to include all new services, controllers, and models
- **System Dependencies**: Added FFmpeg requirement with installation instructions
- **Docker Support**: Added Dockerfile snippet for FFmpeg installation
- **Dependency Verification**: Added initializer for runtime dependency checks

### v1.2 (2026-01-01)
- **Simplified transcription**: Use `RubyLLM.transcribe()` instead of custom OpenAI client
- Removed `Aloo::OpenaiClient` (no longer needed)
- Added complete `Aloo::AudioTranscriptionService` implementation using RubyLLM
- Added RubyLLM transcription model options table
- Updated dependencies to require RubyLLM v1.9.0+
- Added RubyLLM version check instructions

### v1.1 (2026-01-01)
- Removed all enterprise/ directory dependencies
- Clarified that all code will be in `app/` directory
- Added more detailed service implementations
- Updated file structure and dependencies
