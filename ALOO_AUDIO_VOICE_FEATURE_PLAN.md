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
  end
end
```

#### 1.2 Add ElevenLabs API Key Configuration
```ruby
# Add to installation_config or account settings
# ELEVENLABS_API_KEY - stored securely
```

#### 1.3 Create OpenAI Client for Whisper
```ruby
# app/services/aloo/openai_client.rb
module Aloo
  class OpenaiClient
    # Wrapper around OpenAI API for audio transcription
    # Uses OPENAI_API_KEY from environment
    # Provides:
    #   - transcribe(file_path:, language: nil) -> String
    #   - Uses Whisper-1 model
  end
end
```

#### 1.4 Create Audio Transcription Service for Aloo
```ruby
# app/services/aloo/audio_transcription_service.rb
module Aloo
  class AudioTranscriptionService
    WHISPER_MODEL = 'whisper-1'.freeze

    attr_reader :attachment, :message, :assistant

    def initialize(attachment)
      @attachment = attachment
      @message = attachment.message
      @assistant = message.inbox.aloo_assistant
    end

    def perform
      return { error: 'No assistant configured' } unless assistant&.voice_input_enabled?
      return { success: true, transcription: cached_transcription } if cached_transcription.present?

      transcription = transcribe_audio
      store_transcription(transcription)
      notify_message_updated

      { success: true, transcription: transcription }
    end

    private

    def transcribe_audio
      # 1. Download audio file from ActiveStorage
      # 2. Call OpenAI Whisper API via Aloo::OpenaiClient
      # 3. Return transcribed text
    end

    def store_transcription(text)
      # Store in attachment.meta['transcribed_text']
    end

    def cached_transcription
      attachment.meta&.dig('transcribed_text')
    end

    def notify_message_updated
      # Dispatch MESSAGE_UPDATED event for real-time UI update
    end
  end
end
```

#### 1.5 Create Audio Transcription Job
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

#### 1.6 Modify AlooAgentListener
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

#### 1.7 Modify Aloo::ResponseJob
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
# Update existing Aloo::AssistantsController
# Add voice_config params to permitted parameters
# Add endpoint to list available voices from ElevenLabs
```

---

## File Structure

```
app/
├── jobs/
│   └── aloo/
│       ├── audio_transcription_job.rb    # NEW - Async transcription processing
│       └── voice_reply_job.rb            # NEW - Async TTS generation
├── services/
│   └── aloo/
│       ├── openai_client.rb               # NEW - OpenAI API wrapper for Whisper
│       ├── audio_transcription_service.rb # NEW - Transcription orchestration
│       ├── elevenlabs_client.rb           # NEW - ElevenLabs API wrapper
│       ├── voice_synthesis_service.rb     # NEW - TTS orchestration
│       └── voice_message_sender_service.rb # NEW - Channel-specific voice sending
├── listeners/
│   └── aloo_agent_listener.rb             # MODIFY - Add audio message handling
├── models/
│   └── aloo/
│       └── assistant.rb                   # MODIFY (add voice config accessors)
└── javascript/
    └── dashboard/
        └── routes/dashboard/settings/aloo/
            └── components/
                └── VoiceSettings.vue      # NEW - Voice configuration UI

db/
└── migrate/
    └── XXXXXX_add_voice_settings_to_aloo_assistants.rb # NEW

config/
└── locales/
    └── en.yml                             # MODIFY (add voice i18n keys)
```

**All new code will be created in `app/` directory - no enterprise/ dependencies.**

---

## API Integrations

### OpenAI Whisper (Transcription)
- Already available via RubyLLM
- Model: `whisper-1`
- Languages: Auto-detect or specified
- Audio formats: mp3, mp4, mpeg, mpga, m4a, wav, webm, ogg

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
gem 'ruby-openai'  # For Whisper transcription API
gem 'down'         # For file downloads (already present)
gem 'marcel'       # For MIME type detection (already present)
gem 'httparty'     # For ElevenLabs API calls (already present)
```

### Environment Variables
```env
# Already configured
OPENAI_API_KEY=xxx          # Used for Whisper transcription

# New - for ElevenLabs
ELEVENLABS_API_KEY=xxx      # ElevenLabs API key for TTS
```

### Node Packages
No additional packages needed.

---

## Approval Checklist

- [ ] Architecture review approved
- [ ] Database schema approved
- [ ] API integration approach approved
- [ ] Cost model accepted
- [ ] Security review completed
- [ ] Open questions resolved

---

**Document Version**: 1.1
**Created**: 2026-01-01
**Updated**: 2026-01-01
**Author**: Aloo AI Development Team
**Status**: AWAITING REVIEW

---

## Changelog

### v1.1 (2026-01-01)
- Removed all enterprise/ directory dependencies
- Added `Aloo::OpenaiClient` for direct Whisper API access
- Clarified that all code will be in `app/` directory
- Added more detailed service implementations
- Updated file structure and dependencies
