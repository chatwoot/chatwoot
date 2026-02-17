# frozen_string_literal: true

# ElevenLabs text-to-speech agent for Aloo voice replies.
#
# Defaults are overridden per-call with assistant-specific config:
#   Audio::AlooSpeaker.call(
#     text: sanitized_text,
#     voice_id: assistant.elevenlabs_voice_id,
#     model: assistant.effective_tts_model,
#     voice_settings: { stability: 0.5, similarity_boost: 0.75 }
#   )
#
class Audio::AlooSpeaker < Audio::ApplicationSpeaker
  provider :elevenlabs
  model 'eleven_multilingual_v2'

  voice_settings do
    stability 0.5
    similarity_boost 0.75
  end

  reliability do
    retries max: 3, backoff: :exponential
    fallback_models 'eleven_turbo_v2'
    total_timeout 60
  end
end
