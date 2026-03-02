# frozen_string_literal: true

# ElevenLabs voice provider with Conversational AI (real-time) and TTS support.
#
# Real-time: Uses ElevenLabs Conversational AI WebSocket API
#   wss://api.elevenlabs.io/v1/convai/conversation?agent_id={id}
#   Supports native µ-law 8kHz output — perfect for Twilio without transcoding.
#
# TTS: Uses ElevenLabs Text-to-Speech API
#   POST https://api.elevenlabs.io/v1/text-to-speech/{voice_id}
#
# Reference: https://elevenlabs.io/docs/api-reference
module Voice
  module Provider
    class Elevenlabs < Base
      CONVAI_WS_URL = 'wss://api.elevenlabs.io/v1/convai/conversation'
      TTS_API_URL = 'https://api.elevenlabs.io/v1/text-to-speech'
      DEFAULT_VOICE_ID = '21m00Tcm4TlvDq8ikWAM' # Rachel
      DEFAULT_MODEL_ID = 'eleven_turbo_v2_5'
      CONNECT_TIMEOUT = 10

      def initialize(ai_agent:, conversation: nil, api_key: nil)
        super
        @api_key = api_key || ENV.fetch('ELEVENLABS_API_KEY', nil)
        @ws = nil
        @mutex = Mutex.new
      end

      def realtime?
        elevenlabs_agent_id.present?
      end

      # ElevenLabs supports native µ-law for Twilio
      def expected_input_format
        :g711_ulaw
      end

      def output_audio_format
        :g711_ulaw
      end

      # Connect to ElevenLabs Conversational AI WebSocket
      def connect!
        agent_id = elevenlabs_agent_id
        raise 'ElevenLabs agent_id required for Conversational AI' if agent_id.blank?

        url = "#{CONVAI_WS_URL}?agent_id=#{agent_id}"
        @state = :connecting
        connect_with_faye(url)
        @state
      end

      # Send audio (base64-encoded µ-law) to ElevenLabs
      def send_audio(audio_base64)
        return unless @state == :connected

        send_ws_message({
                          user_audio_chunk: audio_base64
                        })
      end

      def disconnect!
        @mutex.synchronize do
          @state = :disconnected
          @ws&.close
          @ws = nil
        end
      end

      # TTS via ElevenLabs REST API
      # Returns base64-encoded audio in the requested format
      def synthesize(text, **options)
        raise 'ElevenLabs API key required' if @api_key.blank?

        voice_id = options[:voice_id] || elevenlabs_voice_id
        model_id = options[:model_id] || elevenlabs_model_id

        uri = URI("#{TTS_API_URL}/#{voice_id}")
        request = Net::HTTP::Post.new(uri)
        request['xi-api-key'] = @api_key
        request['Content-Type'] = 'application/json'
        request['Accept'] = 'audio/mpeg'

        body = {
          text: text.truncate(5000),
          model_id: model_id,
          voice_settings: {
            stability: voice_config_value('stability') || 0.5,
            similarity_boost: voice_config_value('similarity_boost') || 0.75,
            style: voice_config_value('style') || 0.0,
            use_speaker_boost: voice_config_value('use_speaker_boost') != false
          }
        }

        # For Twilio integration, request µ-law format directly
        output_format = options[:output_format] || voice_config_value('output_format')
        uri.query = "output_format=#{output_format}" if output_format

        request.body = body.to_json

        response = perform_http_request(uri, request)
        return nil unless response.is_a?(Net::HTTPSuccess)

        Base64.strict_encode64(response.body)
      end

      # ElevenLabs doesn't have its own STT — delegate to OpenAI Whisper via LiteLLM
      def transcribe(audio_file_path:, language: nil)
        openai_provider = Voice::Provider::Openai.new(ai_agent: @ai_agent, conversation: @conversation)
        openai_provider.transcribe(audio_file_path: audio_file_path, language: language)
      end

      private

      def connect_with_faye(url)
        connected = Concurrent::Event.new

        Thread.new do
          EM.run do
            headers = {}
            headers['xi-api-key'] = @api_key if @api_key.present?

            @ws = Faye::WebSocket::Client.new(url, nil, headers: headers)

            @ws.on :open do |_event|
              @state = :connected
              configure_conversation!
              connected.set
            end

            @ws.on :message do |event|
              handle_server_event(event.data)
            end

            @ws.on :error do |event|
              @state = :error
              fire_error(event.message || 'ElevenLabs WebSocket error')
              connected.set
            end

            @ws.on :close do |_event|
              @state = :disconnected unless @state == :error
              EM.stop if EM.reactor_running?
            end
          end
        end

        unless connected.wait(CONNECT_TIMEOUT)
          @state = :error
          fire_error("ElevenLabs connection timeout after #{CONNECT_TIMEOUT}s")
        end
      end

      def configure_conversation!
        # ElevenLabs Conversational AI configuration is set via the agent_id
        # Additional overrides can be sent via the initial message
        overrides = {}

        # Override system prompt if set on our agent
        prompt = @ai_agent.system_prompt.presence
        overrides[:agent] = { prompt: { prompt: prompt } } if prompt

        # Override first message / greeting
        greeting = voice_config_value('greeting')
        overrides[:agent] ||= {}
        overrides[:agent][:first_message] = greeting if greeting.present?

        return if overrides.blank?

        send_ws_message({
                          type: 'conversation_initiation_client_data',
                          conversation_config_override: overrides
                        })
      end

      def handle_server_event(raw)
        event = JSON.parse(raw)
        type = event['type']

        case type
        when 'audio'
          # ElevenLabs sends audio chunks
          audio_data = event.dig('audio', 'chunk') || event['audio_event']&.dig('audio_base_64')
          fire_audio_delta(audio_data) if audio_data.present?
        when 'agent_response'
          # Agent text response
          text = event.dig('agent_response_event', 'agent_response') || event['agent_response']
          save_agent_transcript(text) if text.present?
          fire_transcript(text, :final)
        when 'user_transcript'
          # User speech transcript
          text = event.dig('user_transcription_event', 'user_transcript') || event['user_transcript']
          save_user_transcript(text) if text.present?
        when 'interruption'
          Rails.logger.debug('[Voice::Provider::Elevenlabs] User interrupted agent')
        when 'ping'
          # Respond to keep-alive pings
          send_ws_message({ type: 'pong', event_id: event['ping_event']&.dig('event_id') })
        when 'conversation_initiation_metadata'
          Rails.logger.info("[Voice::Provider::Elevenlabs] Conversation initialized: #{event.dig('conversation_id')}")
        when 'error'
          fire_error(event.dig('error', 'message') || event['message'] || 'ElevenLabs error')
        end
      rescue JSON::ParserError => e
        fire_error("JSON parse error: #{e.message}")
      end

      def send_ws_message(data)
        @mutex.synchronize do
          return unless @ws

          @ws.send(data.to_json)
        end
      end

      def perform_http_request(uri, request, timeout: 30)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        http.read_timeout = timeout
        http.request(request)
      rescue StandardError => e
        fire_error("HTTP request failed: #{e.message}")
        nil
      end

      # Config accessors

      def elevenlabs_agent_id
        voice_config_value('elevenlabs_agent_id')
      end

      def elevenlabs_voice_id
        voice_config_value('elevenlabs_voice_id') || DEFAULT_VOICE_ID
      end

      def elevenlabs_model_id
        voice_config_value('elevenlabs_model_id') || DEFAULT_MODEL_ID
      end
    end
  end
end
