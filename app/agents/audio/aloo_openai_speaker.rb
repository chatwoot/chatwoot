# frozen_string_literal: true

# OpenAI text-to-speech agent for Aloo voice replies.
#
# Used when assistant's tts_provider is 'openai':
#   Audio::AlooOpenaiSpeaker.call(
#     text: sanitized_text,
#     voice: assistant.openai_voice || 'alloy',
#     model: assistant.effective_tts_model
#   )
#
class Audio::AlooOpenaiSpeaker < Audio::ApplicationSpeaker
  provider :openai
  model 'tts-1'
  voice 'alloy'

  reliability do
    retries max: 3, backoff: :exponential
    fallback_models 'tts-1-hd'
    total_timeout 60
  end
end
