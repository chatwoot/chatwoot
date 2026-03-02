# frozen_string_literal: true

# DEPRECATED: Use Voice::Provider.for(ai_agent:) instead.
# This class is kept as a compatibility shim for any direct references.
#
# The provider-agnostic architecture is now in:
#   Voice::Provider::Base     — abstract interface
#   Voice::Provider::Openai   — OpenAI Realtime API
#   Voice::Provider::Elevenlabs — ElevenLabs Conversational AI
#   Voice::Provider.for(...)  — factory method
module Voice
  class RealtimeSession
    delegate :connect!, :send_audio, :disconnect!, :session_id, :state, to: :@provider

    def initialize(ai_agent:, conversation: nil, api_key: nil)
      @provider = Voice::Provider.for(ai_agent: ai_agent, conversation: conversation, api_key: api_key)
    end

    def on_audio_delta(&block)
      @provider.on_audio_delta(&block)
    end

    def on_transcript(&block)
      @provider.on_transcript(&block)
    end

    def on_error(&block)
      @provider.on_error(&block)
    end

    # OpenAI-specific methods — pass through if provider supports them
    def commit_audio!
      @provider.commit_audio! if @provider.respond_to?(:commit_audio!)
    end

    def send_text(text)
      @provider.send_text(text) if @provider.respond_to?(:send_text)
    end

    def interrupt!
      @provider.interrupt! if @provider.respond_to?(:interrupt!)
    end
  end
end
