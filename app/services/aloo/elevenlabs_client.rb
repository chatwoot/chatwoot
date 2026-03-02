# frozen_string_literal: true

module Aloo
  class ElevenlabsClient
    BASE_URL = 'https://api.elevenlabs.io/v1'
    DEFAULT_MODEL = 'eleven_v3'
    DEFAULT_OUTPUT_FORMAT = 'mp3_44100_128'
    REQUEST_TIMEOUT = 60

    class Error < StandardError; end
    class AuthenticationError < Error; end
    class RateLimitError < Error; end
    class InvalidVoiceError < Error; end

    def initialize(api_key: nil)
      @api_key = api_key || fetch_api_key
      raise AuthenticationError, 'ElevenLabs API key not configured' if @api_key.blank?
    end

    # @deprecated Use Audio::AlooSpeaker.call(text:, voice_id:, ...) instead.
    #   The ruby_llm-agents Speaker DSL handles retries, fallbacks, and cost tracking.
    def text_to_speech(text:, voice_id:, model_id: nil, voice_settings: {})
      validate_text!(text)

      response = HTTParty.post(
        "#{BASE_URL}/text-to-speech/#{voice_id}",
        headers: headers,
        body: build_tts_body(text, model_id, voice_settings).to_json,
        timeout: REQUEST_TIMEOUT
      )

      handle_response(response)
    end

    # List all available voices
    def list_voices
      response = HTTParty.get(
        "#{BASE_URL}/voices",
        headers: headers,
        timeout: REQUEST_TIMEOUT
      )

      result = handle_json_response(response)
      result['voices'] || []
    end

    # Get details for a specific voice
    def get_voice(voice_id)
      response = HTTParty.get(
        "#{BASE_URL}/voices/#{voice_id}",
        headers: headers,
        timeout: REQUEST_TIMEOUT
      )

      handle_json_response(response)
    end

    # Get user subscription info (for quota checking)
    def get_subscription
      response = HTTParty.get(
        "#{BASE_URL}/user/subscription",
        headers: headers,
        timeout: REQUEST_TIMEOUT
      )

      handle_json_response(response)
    end

    # Get available models
    def list_models
      response = HTTParty.get(
        "#{BASE_URL}/models",
        headers: headers,
        timeout: REQUEST_TIMEOUT
      )

      handle_json_response(response)
    end

    private

    def headers
      {
        'xi-api-key' => @api_key,
        'Content-Type' => 'application/json',
        'Accept' => 'audio/mpeg'
      }
    end

    def build_tts_body(text, model_id, voice_settings)
      body = {
        text: text,
        model_id: model_id || DEFAULT_MODEL,
        output_format: DEFAULT_OUTPUT_FORMAT
      }

      if voice_settings.present?
        body[:voice_settings] = {
          stability: voice_settings[:stability] || 0.5,
          similarity_boost: voice_settings[:similarity_boost] || 0.75
        }
      end

      body
    end

    def validate_text!(text)
      raise Error, 'Text cannot be blank' if text.blank?
      raise Error, 'Text exceeds maximum length (5000 characters)' if text.length > 5000
    end

    def handle_response(response)
      case response.code
      when 200
        response.body
      when 401
        raise AuthenticationError, 'Invalid API key'
      when 422
        error_detail = parse_error(response)
        raise InvalidVoiceError, error_detail
      when 429
        raise RateLimitError, 'Rate limit exceeded. Please try again later.'
      else
        error_detail = parse_error(response)
        raise Error, "ElevenLabs API error (#{response.code}): #{error_detail}"
      end
    end

    def handle_json_response(response)
      case response.code
      when 200
        JSON.parse(response.body)
      when 401
        raise AuthenticationError, 'Invalid API key'
      when 429
        raise RateLimitError, 'Rate limit exceeded'
      else
        error_detail = parse_error(response)
        raise Error, "ElevenLabs API error (#{response.code}): #{error_detail}"
      end
    end

    def parse_error(response)
      parsed = JSON.parse(response.body)
      detail = parsed['detail']

      if detail.is_a?(Hash)
        detail['message'] || detail.to_s
      else
        detail || 'Unknown error'
      end
    rescue JSON::ParserError
      response.body.to_s.truncate(200)
    end

    def fetch_api_key
      # Try account-level first, then installation config
      Current.account&.custom_attributes&.dig('elevenlabs_api_key') ||
        InstallationConfig.find_by(name: 'ELEVENLABS_API_KEY')&.value ||
        ENV.fetch('ELEVENLABS_API_KEY', nil)
    end
  end
end
