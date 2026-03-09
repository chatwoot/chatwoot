# frozen_string_literal: true

class Messages::InstagramRendererMapper
  MAX_CARDS = 10
  MAX_BTNS = 3
  MAX_PAYLOAD_SIZE = 25.kilobytes
  TITLE_LIMIT = 180
  DESCRIPTION_LIMIT = 200
  CACHE_TTL = 1.hour

  # Result structure for mapped payload
  Mapped = Struct.new(:content_type, :content_attributes, :fallback_text)

  class << self
    # Main entry point for mapping Instagram rich payloads to Chatwoot structures
    # @param rich_payload [Hash] Instagram rich message payload
    # @return [Mapped] Mapped structure with content_type, content_attributes, and fallback_text
    def map(rich_payload)
      return default_text_mapping(rich_payload) if invalid_payload?(rich_payload)
      return default_text_mapping(rich_payload) if payload_too_large?(rich_payload)

      # Cache based on payload hash for performance
      cache_key = generate_cache_key(rich_payload)
      Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
        map_payload(rich_payload)
      end
    end

    private

    # Validate payload structure and size
    def invalid_payload?(payload)
      return true unless payload.is_a?(Hash)
      return true if payload.empty?

      false
    end

    # Check if payload exceeds size limit
    def payload_too_large?(payload)
      payload.to_json.bytesize > MAX_PAYLOAD_SIZE
    end

    # Generate MD5 cache key from payload
    def generate_cache_key(payload)
      hash = Digest::MD5.hexdigest(payload.to_json)
      # bump version to invalidate stale mappings after logic changes
      "instagram_mapper:v2:#{hash}"
    end

    # Map payload based on template type
    def map_payload(rich_payload)
      case rich_payload['template_type']
      when 'generic'
        to_cards_from_generic(rich_payload)
      when 'button'
        to_cards_from_button(rich_payload)
      else
        # Check for quick replies
        if rich_payload['quick_replies'].is_a?(Array) && rich_payload['quick_replies'].any?
          to_input_select_from_quick_replies(rich_payload)
        else
          # Default fallback for unknown types
          default_text_mapping(rich_payload)
        end
      end
    rescue StandardError => e
      Rails.logger.error "[INSTAGRAM-MAPPER] Mapping failed: #{e.class}: #{e.message}"
      default_text_mapping(rich_payload)
    end

    # Convert Generic Template to cards structure
    def to_cards_from_generic(payload)
      elements = Array(payload['elements']).first(MAX_CARDS)
      return default_text_mapping(payload) if elements.empty?

      items = elements.map do |element|
        build_card_item(element)
      end.compact

      # Generate fallback text from first card
      first_card = items.first || {}
      fallback = generate_fallback_text(first_card['title'], first_card['description'])

      Mapped.new('cards', sanitize_cards({ 'items' => items }), fallback)
    end

    # Convert Button Template to single card structure
    def to_cards_from_button(payload)
      text = payload['text'].to_s.strip
      buttons = Array(payload['buttons']).first(MAX_BTNS)

      return default_text_mapping(payload) if text.blank? && buttons.empty?

      # Create single card with text as the title and buttons as actions
      card_item = {
        'title' => text.present? ? text.truncate(TITLE_LIMIT) : nil,
        'actions' => map_buttons(buttons)
      }.compact

      fallback = text.presence || 'Button template'

      Mapped.new('cards', sanitize_cards({ 'items' => [card_item] }), fallback)
    end

    # Convert Quick Replies to cards structure (using RichCards component)
    def to_input_select_from_quick_replies(payload)
      quick_replies = Array(payload['quick_replies'])
      return default_text_mapping(payload) if quick_replies.empty?

      # Convert quick replies to postback buttons for RichCards
      buttons = quick_replies.map do |quick_reply|
        title = quick_reply['title'].to_s.strip
        payload_value = quick_reply['payload'].to_s.strip

        next if title.blank? || payload_value.blank?

        {
          'type' => 'postback',
          'text' => title.truncate(50),
          'payload' => payload_value
        }
      end.compact

      return default_text_mapping(payload) if buttons.empty?

      text = payload['text'].to_s.strip.presence || 'Select an option'

      # Create a single card with the text and quick reply buttons
      card_item = {
        'title' => text.truncate(TITLE_LIMIT),
        'actions' => buttons
      }

      fallback = "#{text} (#{buttons.length} options)"

      # Use 'cards' content_type to render with RichCards component
      Mapped.new('cards', sanitize_cards({ 'items' => [card_item] }), fallback)
    end

    # Ensure only allowed keys are present in items/actions for 'cards'
    def sanitize_cards(content_attributes)
      return { 'items' => [] } unless content_attributes.is_a?(Hash)

      allowed_item_keys = %w[title description media_url actions]

      items = Array(content_attributes['items']).map do |item|
        next unless item.is_a?(Hash)

        sanitized = {}
        sanitized['title'] = item['title'] if item.key?('title') && item['title'].present?
        sanitized['description'] = item['description'] if item.key?('description') && item['description'].present?
        sanitized['media_url'] = item['media_url'] if item.key?('media_url') && item['media_url'].present?

        if item['actions'].is_a?(Array)
          sanitized['actions'] = item['actions'].map do |action|
            next unless action.is_a?(Hash)

            {
              'text' => action['text'],
              'type' => action['type'],
              'payload' => action['payload'],
              'uri' => action['uri']
            }.compact
          end.compact
        end

        # Drop unknown keys defensively
        sanitized.slice(*allowed_item_keys)
      end.compact

      { 'items' => items }
    end

    # Build individual card item from element
    def build_card_item(element)
      return nil unless element.is_a?(Hash)

      title = element['title'].to_s.strip
      subtitle = element['subtitle'].to_s.strip
      image_url = element['image_url'].to_s.strip
      buttons = Array(element['buttons'])

      # Skip cards without title
      return nil if title.blank?

      card = {
        'title' => title.truncate(TITLE_LIMIT)
      }

      # Add optional fields
      card['description'] = subtitle.truncate(DESCRIPTION_LIMIT) if subtitle.present?
      card['media_url'] = safe_url(image_url) if image_url.present?

      # Add buttons as actions
      actions = map_buttons(buttons.first(MAX_BTNS))
      card['actions'] = actions if actions.any?

      card
    end

    # Map Instagram buttons to Chatwoot actions
    def map_buttons(buttons)
      return [] unless buttons.is_a?(Array)

      buttons.map do |button|
        next unless button.is_a?(Hash)

        button_type = button['type'].to_s
        title = button['title'].to_s.strip

        next if title.blank?

        case button_type
        when 'web_url'
          url = safe_url(button['url'])
          next unless url

          {
            'type' => 'link',
            'text' => title.truncate(50),
            'uri' => url
          }
        when 'postback'
          payload = button['payload'].to_s.strip
          next if payload.blank?

          {
            'type' => 'postback',
            'text' => title.truncate(50),
            'payload' => payload
          }
        end
      end.compact
    end

    # Sanitize and validate URLs
    def safe_url(url)
      return nil if url.blank?

      # Parse and validate URL
      uri = URI.parse(url.strip)
      return nil unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

      # Basic security checks
      return nil if uri.host.blank?
      return nil if uri.host.match?(/localhost|127\.0\.0\.1|0\.0\.0\.0/i)

      uri.to_s
    rescue URI::InvalidURIError => e
      Rails.logger.warn "[INSTAGRAM-MAPPER] Invalid URL: #{url} - #{e.message}"
      nil
    end

    # Generate fallback text from title and description
    def generate_fallback_text(title, description)
      parts = [title, description].compact.map(&:strip).reject(&:blank?)
      return 'Rich message' if parts.empty?

      parts.join(' — ')
    end

    # Default text mapping for unsupported or invalid payloads
    def default_text_mapping(payload)
      text = extract_text_from_payload(payload)
      Mapped.new('text', {}, text)
    end

    # Extract text content from various payload formats
    def extract_text_from_payload(payload)
      return 'Rich message' unless payload.is_a?(Hash)

      # Try different text fields
      text = payload['text'].to_s.strip.presence ||
             payload['elements']&.first&.dig('title').to_s.strip.presence ||
             payload['quick_replies']&.first&.dig('title').to_s.strip.presence ||
             'Rich message'

      text.truncate(500)
    end
  end
end
