# frozen_string_literal: true

# OpenAI Realtime API provider for bidirectional voice streaming.
#
# Uses Faye::WebSocket::Client to maintain a persistent WebSocket connection
# to OpenAI's Realtime API. Audio is streamed as g711_ulaw (matching Twilio's
# native format) to avoid transcoding overhead.
#
# Reference: https://platform.openai.com/docs/guides/realtime
module Voice
  module Provider
    class Openai < Base
      OPENAI_REALTIME_URL = 'wss://api.openai.com/v1/realtime'
      DEFAULT_VOICE = 'alloy'
      DEFAULT_MODEL = 'gpt-4o-realtime-preview'
      CONNECT_TIMEOUT = 10 # seconds

      def initialize(ai_agent:, conversation: nil, api_key: nil)
        super
        @api_key = api_key || ENV.fetch('OPENAI_API_KEY', nil)
        @ws = nil
        @mutex = Mutex.new
      end

      def realtime?
        true
      end

      # OpenAI Realtime now supports g711_ulaw natively — no transcoding needed for Twilio
      def expected_input_format
        :g711_ulaw
      end

      def output_audio_format
        :g711_ulaw
      end

      # Connect to OpenAI Realtime API
      def connect!
        raise 'API key required for OpenAI Realtime API' if @api_key.blank?

        model = voice_config_value('realtime_model') || DEFAULT_MODEL
        url = "#{OPENAI_REALTIME_URL}?model=#{model}"

        headers = {
          'Authorization' => "Bearer #{@api_key}",
          'OpenAI-Beta' => 'realtime=v1'
        }

        @state = :connecting
        connect_with_faye(url, headers)
        @state
      end

      # Send audio (base64-encoded g711_ulaw) to OpenAI
      def send_audio(audio_base64)
        return unless @state == :connected

        send_event('input_audio_buffer.append', { audio: audio_base64 })
      end

      # Commit buffered audio and request a response
      def commit_audio!
        return unless @state == :connected

        send_event('input_audio_buffer.commit', {})
      end

      # Send text message (for testing / fallback)
      def send_text(text)
        return unless @state == :connected

        send_event('conversation.item.create', {
                     item: {
                       type: 'message',
                       role: 'user',
                       content: [{ type: 'input_text', text: text }]
                     }
                   })
        send_event('response.create', {})
      end

      # Interrupt current response
      def interrupt!
        return unless @state == :connected

        send_event('response.cancel', {})
      end

      # Gracefully close
      def disconnect!
        @mutex.synchronize do
          @state = :disconnected
          @ws&.close
          @ws = nil
        end
      end

      # TTS via OpenAI API (for fallback pipeline)
      def synthesize(text, **options)
        voice = options[:voice] || voice_config_value('voice') || DEFAULT_VOICE
        model = options[:model] || 'tts-1'

        uri = URI("#{litellm_base_url}/v1/audio/speech")
        request = Net::HTTP::Post.new(uri)
        request['Authorization'] = "Bearer #{litellm_api_key}"
        request['Content-Type'] = 'application/json'
        request.body = {
          model: model,
          input: text.truncate(4096),
          voice: voice,
          response_format: options[:format] || 'mp3'
        }.to_json

        response = perform_http_request(uri, request)
        return nil unless response.is_a?(Net::HTTPSuccess)

        Base64.strict_encode64(response.body)
      end

      # STT via OpenAI Whisper (for fallback pipeline)
      def transcribe(audio_file_path:, language: nil)
        uri = URI("#{litellm_base_url}/v1/audio/transcriptions")
        request = Net::HTTP::Post.new(uri)
        request['Authorization'] = "Bearer #{litellm_api_key}"

        File.open(audio_file_path) do |file|
          form_data = [
            ['file', file],
            ['model', 'whisper-1']
          ]
          form_data << ['language', language] if language.present?
          request.set_form(form_data, 'multipart/form-data')

          response = perform_http_request(uri, request)
          return nil unless response.is_a?(Net::HTTPSuccess)

          JSON.parse(response.body)['text']
        end
      end

      private

      def connect_with_faye(url, headers)
        # Faye::WebSocket::Client works within EventMachine
        # For synchronous usage, we use a thread + EM reactor
        connected = Concurrent::Event.new

        Thread.new do
          EM.run do
            @ws = Faye::WebSocket::Client.new(url, nil, headers: headers)

            @ws.on :open do |_event|
              @state = :connected
              configure_session!
              connected.set
            end

            @ws.on :message do |event|
              handle_server_event(event.data)
            end

            @ws.on :error do |event|
              @state = :error
              fire_error(event.message || 'WebSocket error')
              connected.set
            end

            @ws.on :close do |_event|
              @state = :disconnected unless @state == :error
              EM.stop if EM.reactor_running?
            end
          end
        end

        # Wait for connection with timeout
        unless connected.wait(CONNECT_TIMEOUT)
          @state = :error
          fire_error("Connection timeout after #{CONNECT_TIMEOUT}s")
        end
      end

      def configure_session!
        voice = voice_config_value('voice') || DEFAULT_VOICE
        instructions = @ai_agent.system_prompt.presence || 'You are a helpful voice assistant. Be concise and natural.'

        config = {
          modalities: %w[text audio],
          instructions: instructions,
          voice: voice,
          input_audio_format: 'g711_ulaw',
          output_audio_format: 'g711_ulaw',
          input_audio_transcription: { model: 'whisper-1' },
          turn_detection: {
            type: 'server_vad',
            threshold: voice_config_value('vad_threshold') || 0.5,
            prefix_padding_ms: 300,
            silence_duration_ms: voice_config_value('silence_duration_ms') || 500
          }
        }

        # Add tools if agent has them
        tools = @ai_agent.tool_definitions
        config[:tools] = tools if tools.present?

        send_event('session.update', { session: config })
      end

      def handle_server_event(raw)
        event = JSON.parse(raw)
        type = event['type']

        case type
        when 'response.audio.delta'
          fire_audio_delta(event['delta'])
        when 'response.audio_transcript.delta'
          fire_transcript(event['delta'], :partial)
        when 'response.audio_transcript.done'
          fire_transcript(event['transcript'], :final)
        when 'conversation.item.input_audio_transcription.completed'
          save_user_transcript(event['transcript'])
        when 'response.done'
          handle_response_done(event)
        when 'error'
          fire_error(event.dig('error', 'message') || 'Unknown realtime error')
        end
      rescue JSON::ParserError => e
        fire_error("JSON parse error: #{e.message}")
      end

      def handle_response_done(event)
        output = event.dig('response', 'output') || []
        output.each do |item|
          next unless item['type'] == 'message'

          content_parts = item['content'] || []
          transcript = content_parts.filter_map { |c| c['transcript'] if c['type'] == 'audio' }.join
          save_agent_transcript(transcript)
        end
      end

      def send_event(type, data)
        @mutex.synchronize do
          return unless @ws

          payload = { type: type }.merge(data)
          @ws.send(payload.to_json)
        end
      end

      def litellm_base_url
        ENV.fetch('LITELLM_BASE_URL', 'http://localhost:4000')
      end

      def litellm_api_key
        ENV.fetch('LITELLM_API_KEY', '')
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
    end
  end
end
