# frozen_string_literal: true

# Bridges Twilio Voice Media Streams ↔ a Voice Provider (OpenAI / ElevenLabs).
#
# Twilio sends inbound audio via WebSocket Media Streams (µ-law 8kHz).
# Both OpenAI Realtime and ElevenLabs Conversational AI now support
# g711_ulaw natively, so no transcoding is needed.
#
# Usage: Instantiated by VoiceRealtimeChannel or TwilioController.
module Voice
  class TwilioBridge
    attr_reader :stream_sid, :call_sid

    def initialize(ai_agent:, conversation: nil, api_key: nil)
      @ai_agent = ai_agent
      @conversation = conversation
      @provider = Voice::Provider.for(ai_agent: ai_agent, conversation: conversation, api_key: api_key)
      @stream_sid = nil
      @call_sid = nil
      @twilio_ws = nil
    end

    # Start the bridge: connect to the voice provider and set up audio forwarding
    def start!(twilio_ws:)
      @twilio_ws = twilio_ws

      # Audio from provider → Twilio
      @provider.on_audio_delta do |audio_base64|
        send_to_twilio(audio_base64)
      end

      @provider.on_error do |message|
        Rails.logger.error("[Voice::TwilioBridge] Provider error: #{message}")
      end

      @provider.connect!
    end

    # Handle a Twilio Media Stream event (called for each WebSocket message from Twilio)
    def handle_twilio_event(data)
      event = data.is_a?(String) ? JSON.parse(data) : data

      case event['event']
      when 'connected'
        Rails.logger.info('[Voice::TwilioBridge] Twilio stream connected')
      when 'start'
        @stream_sid = event.dig('start', 'streamSid')
        @call_sid = event.dig('start', 'callSid')
        Rails.logger.info("[Voice::TwilioBridge] Stream started: #{@stream_sid}")
      when 'media'
        audio_payload = event.dig('media', 'payload')
        @provider.send_audio(audio_payload) if audio_payload.present?
      when 'mark'
        Rails.logger.debug("[Voice::TwilioBridge] Mark: #{event.dig('mark', 'name')}")
      when 'stop'
        Rails.logger.info('[Voice::TwilioBridge] Twilio stream stopped')
        stop!
      end
    rescue JSON::ParserError => e
      Rails.logger.error("[Voice::TwilioBridge] JSON parse error: #{e.message}")
    end

    # Gracefully shut down
    def stop!
      @provider.disconnect!
    end

    # Expose provider for direct access (e.g., interrupt)
    def provider
      @provider
    end

    private

    # Send audio back to Twilio via its Media Stream WebSocket
    def send_to_twilio(audio_base64)
      return unless @twilio_ws && @stream_sid

      message = {
        event: 'media',
        streamSid: @stream_sid,
        media: {
          payload: audio_base64
        }
      }.to_json

      # Use transmit for ActionCable channels, send for raw WebSockets
      if @twilio_ws.respond_to?(:transmit)
        @twilio_ws.transmit(JSON.parse(message))
      else
        @twilio_ws.send(message)
      end
    end
  end
end
