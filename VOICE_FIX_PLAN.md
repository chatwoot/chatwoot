# Voice Fix & ruby_llm-agents Audio Migration Plan

## Problem Summary

### Bug 1: WhatsApp 131053 — Media upload error (`voice_only` mode)
- **Root cause**: Audio attached with `content_type: 'audio/ogg'` but WhatsApp requires `audio/ogg; codecs=opus`
- **Fallback also fails**: When direct upload is rejected, `build_media_content` falls back to `download_url` which returns an internal ActiveStorage URL that WhatsApp servers cannot reach
- **File**: `app/jobs/aloo/voice_reply_job.rb:94-98`, `app/services/whatsapp/providers/whatsapp_cloud_service.rb:150-167`

### Bug 2: Audio silently never sent (`text_and_voice` mode)
- **Root cause**: `VoiceReplyJob` calls `SendOnWhatsappService.new(message:).perform` on a message that already has `source_id` (set by the earlier `SendReplyJob`). The `Base::SendOnChannelService#invalid_message?` guard checks `source_id.present?` and returns early — audio is never delivered
- **File**: `app/services/base/send_on_channel_service.rb:49`, `app/jobs/aloo/voice_reply_job.rb:62-65`

### Improvement: Replace custom ElevenLabs client with ruby_llm-agents Audio
- The `ruby_llm-agents` gem (v3.1.0, already in Gemfile) provides `Speaker` (TTS) and `Transcriber` (STT) base classes with built-in cost tracking, retry/fallback, and a clean DSL
- Currently: custom `Aloo::ElevenlabsClient` + `Aloo::VoiceSynthesisService` + raw `RubyLLM.transcribe`
- Goal: Use the gem's `ApplicationSpeaker` and `ApplicationTranscriber` for unified tracking via `RubyLLM::Agents::Execution`

---

## Plan

### Phase 1: Fix WhatsApp audio delivery (both modes)

#### 1.1 Fix content type on attachment creation

**File**: `app/jobs/aloo/voice_reply_job.rb`

Change `attach_audio_to_message` to use the correct MIME type:

```ruby
# Before
content_type: 'audio/ogg'

# After
content_type: 'audio/ogg; codecs=opus'
```

#### 1.2 Fix `text_and_voice` mode — send audio as a separate WhatsApp message

The current approach of re-calling `SendOnWhatsappService` on the same message is fundamentally broken because the `source_id` guard blocks it. Instead, send the audio attachment directly via the WhatsApp Cloud API, bypassing `SendOnWhatsappService`.

**File**: `app/jobs/aloo/voice_reply_job.rb`

Refactor `send_to_channel` to handle WhatsApp differently:

```ruby
def send_to_channel(message)
  inbox = @conversation.inbox

  case inbox.channel_type
  when 'Channel::Whatsapp'
    send_whatsapp_audio(message)
  when 'Channel::FacebookPage'
    # Facebook handles re-send fine (no source_id guard issue)
    Facebook::SendOnFacebookService.new(message: message).perform
  when 'Channel::Telegram'
    ::SendReplyJob.perform_later(message.id)
  else
    Rails.logger.info("[Aloo::VoiceReplyJob] Message #{message.id} saved for #{inbox.channel_type}")
  end
end
```

Add a new private method `send_whatsapp_audio` that:
1. Gets the WhatsApp channel and phone number from `conversation.contact_inbox.source_id`
2. Uploads the audio attachment directly via `channel.upload_media(attachment)`
3. Sends the audio message via the WhatsApp API with the `media_id`
4. Updates the message's `source_id` if this is a new voice-only message

This bypasses `SendOnWhatsappService` entirely for the audio part, avoiding the `source_id` guard.

#### 1.3 Update `VoiceSynthesisService` result content type

**File**: `app/services/aloo/voice_synthesis_service.rb`

```ruby
# Before
content_type: 'audio/ogg'

# After
content_type: 'audio/ogg; codecs=opus'
```

---

### Phase 2: Create ruby_llm-agents Speaker & Transcriber

#### 2.1 Generate Speaker class

Create `app/agents/audio/aloo_speaker.rb`:

```ruby
class Audio::AlooSpeaker < ApplicationSpeaker
  provider :elevenlabs
  model "eleven_multilingual_v2"
  voice_id "default"  # Overridden per-call

  voice_settings do
    stability 0.5
    similarity_boost 0.75
  end

  reliability do
    retry_on_failure max_attempts: 3
  end

  fallback_models "eleven_turbo_v2"
end
```

The speaker will be called with dynamic per-assistant config:

```ruby
result = Audio::AlooSpeaker.call(
  text: sanitized_text,
  voice_id: assistant.elevenlabs_voice_id,
  model: assistant.effective_tts_model,
  voice_settings: {
    stability: assistant.elevenlabs_stability,
    similarity_boost: assistant.elevenlabs_similarity_boost
  }
)
result.audio       # Binary audio data
result.total_cost  # Cost in USD
result.duration    # Audio duration
```

#### 2.2 Generate Transcriber class

Create `app/agents/audio/aloo_transcriber.rb`:

```ruby
class Audio::AlooTranscriber < ApplicationTranscriber
  model "whisper-1"
  language "en"  # Overridden per-call based on assistant config

  reliability do
    retry_on_failure max_attempts: 3
  end

  fallback_models "gpt-4o-mini-transcribe"
end
```

Called with:

```ruby
result = Audio::AlooTranscriber.call(
  audio: temp_file_path,
  language: language_hint
)
result.text            # Transcription
result.audio_duration  # Duration in seconds
result.total_cost      # Cost in USD
```

#### 2.3 Create `ApplicationSpeaker` and `ApplicationTranscriber` base classes

**File**: `app/agents/application_speaker.rb`
**File**: `app/agents/application_transcriber.rb`

These follow the same pattern as `ApplicationAgent` already in the codebase — setting up tenant context, default config, etc.

---

### Phase 3: Refactor services to use ruby_llm-agents Audio

#### 3.1 Refactor `VoiceSynthesisService`

**File**: `app/services/aloo/voice_synthesis_service.rb`

Replace the direct `ElevenlabsClient` usage:

```ruby
# Before
client = Aloo::ElevenlabsClient.new
audio_data = client.text_to_speech(
  text: sanitized_text,
  voice_id: effective_voice_id,
  model_id: assistant.effective_tts_model,
  voice_settings: voice_settings
)

# After
result = Audio::AlooSpeaker.call(
  text: sanitized_text,
  voice_id: effective_voice_id,
  model: assistant.effective_tts_model,
  voice_settings: voice_settings
)
audio_data = result.audio
```

- The gem handles retries, fallbacks, and error wrapping
- Cost is automatically tracked in `RubyLLM::Agents::Execution`
- Still convert to OGG via `AudioConversionService` (the gem outputs MP3 by default from ElevenLabs)
- Update `record_usage` to also store `result.total_cost` from the gem for cross-reference

#### 3.2 Refactor `AudioTranscriptionService`

**File**: `app/services/aloo/audio_transcription_service.rb`

Replace raw `RubyLLM.transcribe`:

```ruby
# Before
result = RubyLLM.transcribe(
  temp_file.path,
  model: transcription_model,
  language: language_hint
)

# After
result = Audio::AlooTranscriber.call(
  audio: temp_file.path,
  language: language_hint,
  model: assistant.effective_transcription_model
)
```

- Gains automatic retry + fallback to `gpt-4o-mini-transcribe`
- Cost tracked via `RubyLLM::Agents::Execution`
- `result.text` and `result.audio_duration` work the same way

#### 3.3 Deprecate `Aloo::ElevenlabsClient`

After migration, the custom `ElevenlabsClient` is no longer needed for TTS. Keep it temporarily if `list_voices` / `get_voice` / `get_subscription` are used elsewhere (e.g., voice selection UI), but mark TTS methods as deprecated. Eventually remove entirely once all callers migrate.

---

### Phase 4: Unify usage tracking

#### 4.1 Bridge gem tracking with `VoiceUsageRecord`

The gem tracks executions in `RubyLLM::Agents::Execution`. We still want our custom `Aloo::VoiceUsageRecord` for the voice-specific dashboard (daily limits, per-assistant breakdown, etc.).

Update `VoiceUsageRecord.record_synthesis` and `record_transcription` to accept an optional `execution_cost:` parameter from the gem result, so we store the gem's calculated cost alongside our own estimate:

```ruby
def self.record_synthesis(account:, assistant:, characters:, voice_id:, model:, message: nil, success: true, error: nil, execution_cost: nil)
  create!(
    # ... existing fields ...
    metadata: {
      error: error,
      gem_tracked_cost: execution_cost  # from result.total_cost
    }.compact
  )
end
```

#### 4.2 Update `VoiceUsageController` (optional)

If desired, add a field to the usage API response showing the gem's tracked cost alongside the estimated cost, for reconciliation.

---

### Phase 5: Update assistant voice config

#### 5.1 Expand `VALID_TTS_PROVIDERS` to include OpenAI

**File**: `app/models/aloo/assistant.rb`

The gem supports both `:openai` and `:elevenlabs` for TTS. Update the valid providers list:

```ruby
# Before
VALID_TTS_PROVIDERS = ['elevenlabs']

# After
VALID_TTS_PROVIDERS = %w[elevenlabs openai].freeze
```

This allows assistants to use OpenAI TTS (`tts-1`, `tts-1-hd`) as an alternative — no ElevenLabs API key needed.

#### 5.2 Update `voice_reply_enabled?`

Currently requires `elevenlabs_voice_id.present?`. With OpenAI as an option, this should also allow OpenAI voices:

```ruby
def voice_reply_enabled?
  return false unless voice_enabled?

  case tts_provider
  when 'elevenlabs'
    elevenlabs_voice_id.present?
  when 'openai'
    true  # OpenAI uses named voices (alloy, nova, etc.), always available
  else
    false
  end
end
```

#### 5.3 Add OpenAI voice fields to `voice_config` store

Add `openai_voice` accessor (e.g., "nova", "alloy", "echo") for when `tts_provider` is `openai`.

---

## Files Changed Summary

| File | Change |
|------|--------|
| `app/jobs/aloo/voice_reply_job.rb` | Fix content type, add `send_whatsapp_audio`, fix `text_and_voice` flow |
| `app/services/aloo/voice_synthesis_service.rb` | Use `Audio::AlooSpeaker`, fix content type in result |
| `app/services/aloo/audio_transcription_service.rb` | Use `Audio::AlooTranscriber` |
| `app/services/whatsapp/providers/whatsapp_cloud_service.rb` | No changes (upload_media already correct) |
| `app/agents/application_speaker.rb` | **New** — base class |
| `app/agents/application_transcriber.rb` | **New** — base class |
| `app/agents/audio/aloo_speaker.rb` | **New** — ElevenLabs/OpenAI TTS |
| `app/agents/audio/aloo_transcriber.rb` | **New** — Whisper transcription |
| `app/models/aloo/assistant.rb` | Expand TTS providers, update `voice_reply_enabled?` |
| `app/models/aloo/voice_usage_record.rb` | Add `execution_cost` bridge field |
| `app/services/aloo/elevenlabs_client.rb` | Mark TTS method as deprecated |

## Execution Order

1. **Phase 1** first — fixes the production bug immediately
2. **Phase 2** next — creates the new Speaker/Transcriber classes (no breaking changes)
3. **Phase 3** — swaps the service internals (same public API, different implementation)
4. **Phase 4** — bridges usage tracking
5. **Phase 5** — enables OpenAI TTS as an alternative provider

Phases 2-5 can be done in a single PR after Phase 1 is deployed.
