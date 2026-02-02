# frozen_string_literal: true

class Messages::WhatsappRendererMapper
  MAX_BUTTONS = 3
  MAX_LIST_ITEMS = 10
  MAX_PAYLOAD_SIZE = 25.kilobytes
  TITLE_LIMIT = 120
  DESCRIPTION_LIMIT = 200
  CACHE_TTL = 1.hour

  # Result structure for mapped payload
  Mapped = Struct.new(:content_type, :content_attributes, :fallback_text)

  class << self
    # Main entry point for mapping WhatsApp interactive payloads to Chatwoot structures
    # @param interactive_payload [Hash] WhatsApp interactive message payload
    # @return [Mapped] Mapped structure with content_type, content_attributes, and fallback_text
    def map(interactive_payload)
      return default_text_mapping(interactive_payload) if invalid_payload?(interactive_payload)
      return default_text_mapping(interactive_payload) if payload_too_large?(interactive_payload)

      # Cache based on payload hash for performance
      cache_key = generate_cache_key(interactive_payload)
      Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
        map_payload(interactive_payload)
      end
    end

    private

    # Validate payload structure and size
    def invalid_payload?(payload)
      return true unless payload.is_a?(Hash)
      return true if payload.empty?
      return true unless payload['type'].present?

      false
    end

    # Check if payload exceeds size limit
    def payload_too_large?(payload)
      payload.to_json.bytesize > MAX_PAYLOAD_SIZE
    end

    # Generate MD5 cache key from payload
    def generate_cache_key(payload)
      hash = Digest::MD5.hexdigest(payload.to_json)
      "whatsapp_mapper:#{hash}"
    end

    # Map payload based on interactive type
    def map_payload(interactive_payload)
      case interactive_payload['type']
      when 'button'
        to_integrations_from_button(interactive_payload)
      when 'list'
        to_integrations_from_list(interactive_payload)
      else
        # Default fallback for unknown types
        default_text_mapping(interactive_payload)
      end
    rescue StandardError => e
      Rails.logger.error "[WHATSAPP-MAPPER] Mapping failed: #{e.class}: #{e.message}"
      default_text_mapping(interactive_payload)
    end

    # Convert Button Interactive to integrations structure (WhatsAppInteractive.vue)
    def to_integrations_from_button(payload)
      body_text = payload.dig('body', 'text').to_s.strip
      buttons = Array(payload.dig('action', 'buttons')).first(MAX_BUTTONS)

      return default_text_mapping(payload) if body_text.blank? && buttons.empty?

      # Create content_attributes for WhatsAppInteractive.vue
      content_attributes = {
        'interactive' => payload,
        'type' => 'interactive',
        'whatsapp_interactive_payload' => payload,
        'interactive_payload' => payload  # Para evitar atualização posterior no RichMessageService
      }

      fallback = body_text.presence || 'WhatsApp interactive message'

      Mapped.new('integrations', content_attributes, fallback)
    end

    # Convert List Interactive to integrations structure (WhatsAppInteractive.vue)
    def to_integrations_from_list(payload)
      body_text = payload.dig('body', 'text').to_s.strip
      sections = Array(payload.dig('action', 'sections'))

      return default_text_mapping(payload) if body_text.blank? && sections.empty?

      # Create content_attributes for WhatsAppInteractive.vue
      content_attributes = {
        'interactive' => payload,
        'type' => 'interactive',
        'whatsapp_interactive_payload' => payload,
        'interactive_payload' => payload  # Para evitar atualização posterior no RichMessageService
      }

      fallback = body_text.presence || 'WhatsApp interactive message'

      Mapped.new('integrations', content_attributes, fallback)
    end

    # Generate fallback text from interactive payload
    def generate_fallback_text(payload)
      body_text = payload.dig('body', 'text').to_s.strip
      header_text = payload.dig('header', 'text').to_s.strip
      footer_text = payload.dig('footer', 'text').to_s.strip

      parts = [header_text, body_text, footer_text].compact.map(&:strip).reject(&:blank?)
      return 'WhatsApp interactive message' if parts.empty?

      parts.join(' — ').truncate(200)
    end

    # Default text mapping for unsupported or invalid payloads
    def default_text_mapping(payload)
      text = extract_text_from_payload(payload)
      Mapped.new('text', {}, text)
    end

    # Extract text content from various payload formats
    def extract_text_from_payload(payload)
      return 'WhatsApp message' unless payload.is_a?(Hash)

      # Try different text fields
      text = payload.dig('body', 'text').to_s.strip.presence ||
             payload.dig('header', 'text').to_s.strip.presence ||
             payload.dig('footer', 'text').to_s.strip.presence ||
             'WhatsApp message'

      text.truncate(500)
    end
  end
end
