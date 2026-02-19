# frozen_string_literal: true

# OpenAI Whisper transcription agent for Aloo voice messages.
#
# Called with per-assistant config:
#   Audio::AlooTranscriber.call(
#     audio: temp_file_path,
#     language: language_hint,
#     model: assistant.effective_transcription_model
#   )
#
class Audio::AlooTranscriber < Audio::ApplicationTranscriber
  model 'whisper-1'

  reliability do
    retries max: 3, backoff: :exponential
    fallback_models 'gpt-4o-mini-transcribe'
    total_timeout 120
  end
end
