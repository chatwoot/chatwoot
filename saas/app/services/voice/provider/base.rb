# frozen_string_literal: true

# Abstract base class for voice providers (OpenAI Realtime, ElevenLabs Conversational AI, etc.)
#
# Each provider implements:
#   - Real-time audio streaming (send_audio / on_audio callbacks)
#   - Text-to-speech synthesis
#   - Optional speech-to-text transcription
#
# Providers are selected via the `voice_config['provider']` key on AiAgent.
module Voice
  module Provider
    PROVIDERS = {
      'openai' => 'Voice::Provider::Openai',
      'elevenlabs' => 'Voice::Provider::Elevenlabs'
    }.freeze

    DEFAULT_PROVIDER = 'openai'

    # Factory: build a provider instance from the agent's voice_config
    # @param ai_agent [Saas::AiAgent]
    # @param conversation [Conversation, nil]
    # @param api_key [String, nil] override API key
    # @return [Voice::Provider::Base]
    def self.for(ai_agent:, conversation: nil, api_key: nil)
      provider_name = ai_agent.voice_config&.dig('provider') || DEFAULT_PROVIDER
      klass_name = PROVIDERS[provider_name]

      raise ArgumentError, "Unknown voice provider: #{provider_name}. Available: #{PROVIDERS.keys.join(', ')}" unless klass_name

      klass_name.constantize.new(
        ai_agent: ai_agent,
        conversation: conversation,
        api_key: api_key
      )
    end

    class Base
      attr_reader :session_id, :state

      # @param ai_agent [Saas::AiAgent] the agent configuration
      # @param conversation [Conversation, nil] optional conversation for transcript storage
      # @param api_key [String, nil] override API key
      def initialize(ai_agent:, conversation: nil, api_key: nil)
        @ai_agent = ai_agent
        @conversation = conversation
        @api_key = api_key
        @session_id = SecureRandom.uuid
        @state = :initialized
        @callbacks = { audio_delta: nil, transcript: nil, error: nil }
      end

      # Register callback for audio output chunks (base64-encoded)
      def on_audio_delta(&block)
        @callbacks[:audio_delta] = block
      end

      # Register callback for transcripts (:partial or :final)
      def on_transcript(&block)
        @callbacks[:transcript] = block
      end

      # Register callback for errors
      def on_error(&block)
        @callbacks[:error] = block
      end

      # Connect to the real-time API. Returns the state after connection attempt.
      # @return [Symbol] :connected, :error, etc.
      def connect!
        raise NotImplementedError
      end

      # Send audio bytes (base64-encoded) to the provider
      def send_audio(_audio_base64)
        raise NotImplementedError
      end

      # Gracefully close the session
      def disconnect!
        raise NotImplementedError
      end

      # Text-to-speech: synthesize text into audio
      # @param text [String]
      # @param options [Hash] provider-specific options (voice, format, etc.)
      # @return [String, nil] base64-encoded audio or nil on failure
      def synthesize(text, **options)
        raise NotImplementedError
      end

      # Speech-to-text: transcribe audio file
      # @param audio_file_path [String]
      # @param language [String, nil]
      # @return [String, nil] transcribed text
      def transcribe(audio_file_path:, language: nil)
        raise NotImplementedError
      end

      # Whether this provider supports real-time bidirectional audio streaming
      def realtime?
        false
      end

      # Audio format this provider expects from Twilio (for transcoding decisions)
      # Override in subclass. Default: :g711_ulaw (what Twilio sends natively)
      def expected_input_format
        :g711_ulaw
      end

      # Audio format this provider returns (for transcoding decisions)
      def output_audio_format
        :g711_ulaw
      end

      protected

      def fire_audio_delta(audio_base64)
        @callbacks[:audio_delta]&.call(audio_base64)
      end

      def fire_transcript(text, type = :final)
        @callbacks[:transcript]&.call(text, type)
      end

      def fire_error(message)
        Rails.logger.error("[#{self.class.name}] #{message}")
        @callbacks[:error]&.call(message)
      end

      def voice_config_value(key)
        @ai_agent.voice_config&.dig(key)
      end

      def save_user_transcript(transcript)
        return if transcript.blank? || @conversation.blank?

        @conversation.messages.create!(
          content: transcript,
          message_type: :incoming,
          account_id: @conversation.account_id,
          inbox_id: @conversation.inbox_id,
          content_attributes: { voice_transcription: true }
        )
      end

      def save_agent_transcript(transcript)
        return if transcript.blank? || @conversation.blank?

        @conversation.messages.create!(
          content: transcript,
          message_type: :outgoing,
          account_id: @conversation.account_id,
          inbox_id: @conversation.inbox_id,
          content_attributes: { ai_generated: true, voice: true, ai_agent_id: @ai_agent.id }
        )
      end
    end
  end
end
