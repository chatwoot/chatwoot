# frozen_string_literal: true

# Provider-agnostic service for listing available voices and models.
#
# Usage:
#   catalog = Voice::CatalogService.new(provider: 'elevenlabs')
#   catalog.voices   # => [{ id:, name:, gender:, accent:, preview_url:, ... }]
#   catalog.models   # => [{ id:, name:, languages:, ... }]
#   catalog.preview(voice_id: '...', text: 'Hello')  # => base64 audio
module Voice
  class CatalogService
    ELEVENLABS_API_BASE = 'https://api.elevenlabs.io'
    CACHE_TTL = 1.hour

    # OpenAI static voices (no API needed)
    OPENAI_VOICES = [
      { id: 'alloy', name: 'Alloy', gender: 'neutral', accent: 'American', description: 'Neutral and balanced', preview_url: nil, category: 'default' },
      { id: 'ash', name: 'Ash', gender: 'male', accent: 'American', description: 'Soft and conversational', preview_url: nil, category: 'default' },
      { id: 'ballad', name: 'Ballad', gender: 'male', accent: 'American', description: 'Warm and expressive', preview_url: nil, category: 'default' },
      { id: 'coral', name: 'Coral', gender: 'female', accent: 'American', description: 'Clear and friendly', preview_url: nil, category: 'default' },
      { id: 'echo', name: 'Echo', gender: 'male', accent: 'American', description: 'Smooth and clear', preview_url: nil, category: 'default' },
      { id: 'fable', name: 'Fable', gender: 'female', accent: 'British', description: 'Warm and storytelling', preview_url: nil, category: 'default' },
      { id: 'nova', name: 'Nova', gender: 'female', accent: 'American', description: 'Young and energetic', preview_url: nil, category: 'default' },
      { id: 'onyx', name: 'Onyx', gender: 'male', accent: 'American', description: 'Deep and authoritative', preview_url: nil, category: 'default' },
      { id: 'sage', name: 'Sage', gender: 'female', accent: 'American', description: 'Calm and composed', preview_url: nil, category: 'default' },
      { id: 'shimmer', name: 'Shimmer', gender: 'female', accent: 'American', description: 'Bright and optimistic', preview_url: nil, category: 'default' },
      { id: 'verse', name: 'Verse', gender: 'male', accent: 'American', description: 'Articulate and dynamic', preview_url: nil, category: 'default' }
    ].freeze

    OPENAI_MODELS = [
      { id: 'gpt-4o-realtime-preview', name: 'Realtime (GPT-4o)', languages: %w[en es fr de pt ja ko zh] },
      { id: 'gpt-4o-mini-realtime-preview', name: 'Realtime Mini (GPT-4o)', languages: %w[en es fr de pt ja ko zh] },
      { id: 'tts-1', name: 'Standard TTS', languages: %w[en es fr de pt ja ko zh ar hi] },
      { id: 'tts-1-hd', name: 'HD TTS', languages: %w[en es fr de pt ja ko zh ar hi] }
    ].freeze

    def initialize(provider:, api_key: nil)
      @provider = provider
      @api_key = api_key || resolve_api_key(provider)
    end

    def voices
      case @provider
      when 'elevenlabs'
        fetch_elevenlabs_voices
      else
        OPENAI_VOICES
      end
    end

    def models
      case @provider
      when 'elevenlabs'
        fetch_elevenlabs_models
      else
        OPENAI_MODELS
      end
    end

    # Synthesize a short text sample for preview playback.
    # Returns base64-encoded mp3 audio or nil.
    def preview(voice_id:, text: 'Hello! How can I help you today?', model_id: nil, language: nil)
      case @provider
      when 'elevenlabs'
        synthesize_elevenlabs_preview(voice_id, text.truncate(200), model_id, language)
      else
        nil # OpenAI TTS preview not implemented (use voice name to identify)
      end
    end

    private

    def resolve_api_key(provider)
      case provider
      when 'elevenlabs'
        ENV.fetch('ELEVENLABS_API_KEY', nil)
      when 'openai'
        ENV.fetch('OPENAI_API_KEY', nil)
      end
    end

    # ── ElevenLabs: voices ──

    def fetch_elevenlabs_voices
      Rails.cache.fetch("voice_catalog:elevenlabs:voices:#{@api_key.to_s.last(8)}", expires_in: CACHE_TTL) do
        raw_voices = elevenlabs_get('/v2/voices', page_size: 100, include_total_count: false)
        return [] unless raw_voices.is_a?(Hash) && raw_voices['voices']

        raw_voices['voices'].map { |v| normalize_elevenlabs_voice(v) }
      end
    end

    def normalize_elevenlabs_voice(v)
      labels = v['labels'] || {}
      {
        id: v['voice_id'],
        name: v['name'],
        gender: labels['gender'],
        accent: labels['accent'],
        age: labels['age'],
        description: labels['description'] || v['description'],
        use_case: labels['use_case'],
        preview_url: v['preview_url'],
        category: v['category'],
        languages: (v['verified_languages'] || []).map { |l| l['language'] }.compact.uniq,
        high_quality_model_ids: v['high_quality_base_model_ids'] || []
      }
    end

    # ── ElevenLabs: models ──

    def fetch_elevenlabs_models
      Rails.cache.fetch("voice_catalog:elevenlabs:models:#{@api_key.to_s.last(8)}", expires_in: CACHE_TTL) do
        raw_models = elevenlabs_get('/v1/models')
        return [] unless raw_models.is_a?(Array)

        raw_models
          .select { |m| m['can_do_text_to_speech'] }
          .map { |m| normalize_elevenlabs_model(m) }
      end
    end

    def normalize_elevenlabs_model(m)
      {
        id: m['model_id'],
        name: m['name'],
        description: m['description'],
        languages: (m['languages'] || []).map { |l| l['language_id'] }.compact
      }
    end

    # ── ElevenLabs: preview synthesis ──

    def synthesize_elevenlabs_preview(voice_id, text, model_id, language)
      return nil if @api_key.blank?

      model_id ||= 'eleven_multilingual_v2'

      uri = URI("#{ELEVENLABS_API_BASE}/v1/text-to-speech/#{voice_id}?output_format=mp3_22050_32")
      request = Net::HTTP::Post.new(uri)
      request['xi-api-key'] = @api_key
      request['Content-Type'] = 'application/json'
      request['Accept'] = 'audio/mpeg'

      body = {
        text: text,
        model_id: model_id,
        voice_settings: { stability: 0.5, similarity_boost: 0.75, style: 0.0, use_speaker_boost: true }
      }
      body[:language_code] = language if language.present?
      request.body = body.to_json

      response = perform_request(uri, request)
      return nil unless response.is_a?(Net::HTTPSuccess)

      Base64.strict_encode64(response.body)
    end

    # ── HTTP helpers ──

    def elevenlabs_get(path, params = {})
      uri = URI("#{ELEVENLABS_API_BASE}#{path}")
      uri.query = URI.encode_www_form(params) if params.any?

      request = Net::HTTP::Get.new(uri)
      request['xi-api-key'] = @api_key if @api_key.present?
      request['Accept'] = 'application/json'

      response = perform_request(uri, request)
      return nil unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    rescue JSON::ParserError
      nil
    end

    def perform_request(uri, request, timeout: 15)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.read_timeout = timeout
      http.open_timeout = 5
      http.request(request)
    rescue StandardError => e
      Rails.logger.error("[Voice::CatalogService] HTTP error: #{e.class} — #{e.message}")
      nil
    end
  end
end
