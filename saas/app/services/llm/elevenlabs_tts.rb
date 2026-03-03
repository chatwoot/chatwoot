# frozen_string_literal: true

# Generates speech audio using the ElevenLabs Text-to-Speech API.
# Returns raw audio bytes in opus format (optimal for WhatsApp).
#
# Usage:
#   tts = Llm::ElevenlabsTts.new(voice_id: 'RGymW84CSmfVugnA5tvA')
#   audio_bytes = tts.generate('Olá, como posso ajudar?')
#
class Llm::ElevenlabsTts
  BASE_URL = 'https://api.elevenlabs.io/v1'
  DEFAULT_MODEL = 'eleven_multilingual_v2'
  OUTPUT_FORMAT = 'opus_48000_128'

  def initialize(voice_id: nil, api_key: nil, model_id: nil)
    @voice_id = voice_id || ENV.fetch('ELEVENLABS_VOICE_ID', '21m00Tcm4TlvDq8ikWAM')
    @api_key = api_key || ENV.fetch('ELEVENLABS_API_KEY', nil)
    @model_id = model_id || DEFAULT_MODEL
  end

  # Generates speech audio from text. Returns raw audio bytes or nil on failure.
  def generate(text)
    return nil if text.blank? || @api_key.blank?

    uri = URI("#{BASE_URL}/text-to-speech/#{@voice_id}?output_format=#{OUTPUT_FORMAT}")
    request = build_request(uri, text)
    response = execute_request(uri, request)

    if response.is_a?(Net::HTTPSuccess)
      Rails.logger.info "[ELEVENLABS_TTS] Generated #{response.body.bytesize} bytes for #{text.length} chars"
      response.body
    else
      Rails.logger.warn "[ELEVENLABS_TTS] Failed: #{response.code} — #{response.body.truncate(200)}"
      nil
    end
  rescue StandardError => e
    Rails.logger.warn "[ELEVENLABS_TTS] Error: #{e.class} — #{e.message}"
    nil
  end

  private

  def build_request(uri, text)
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request['xi-api-key'] = @api_key
    request.body = {
      text: text,
      model_id: @model_id,
      voice_settings: { stability: 0.5, similarity_boost: 0.8, style: 0.0, use_speaker_boost: true }
    }.to_json
    request
  end

  def execute_request(uri, request)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 30
    http.request(request)
  end
end
