class Whatsapp::InteractiveMessages::Registry
  SCHEMA_VERSION = 1
  BUTTON_TYPE = 'button'.freeze
  BODY_MAX_LENGTH = 1024
  HEADER_MAX_LENGTH = 60
  FOOTER_MAX_LENGTH = 60
  HEADER_TYPES = %w[text image video document].freeze
  BUTTON_TITLE_MAX_LENGTH = 20
  BUTTON_COUNT_RANGE = (1..3)

  IMPLEMENTED_TYPES = [BUTTON_TYPE].freeze

  class << self
    def limits
      {
        body_max_length: BODY_MAX_LENGTH,
        header_max_length: HEADER_MAX_LENGTH,
        footer_max_length: FOOTER_MAX_LENGTH,
        header_types: HEADER_TYPES,
        button_title_max_length: BUTTON_TITLE_MAX_LENGTH,
        button_min_count: BUTTON_COUNT_RANGE.min,
        button_max_count: BUTTON_COUNT_RANGE.max
      }
    end

    def implemented_types
      IMPLEMENTED_TYPES
    end

    def implemented?(type)
      implemented_types.include?(type.to_s)
    end

    def limits_for(type)
      type.to_s == BUTTON_TYPE ? limits : nil
    end

    def resolve(payload)
      path = 'whatsapp_interactive'
      interactive = validated_interactive(payload, path)
      body_text = validated_body_text(interactive, path)
      buttons = validated_buttons(interactive, path)
      value!(BUTTON_COUNT_RANGE.cover?(buttons.length), 'whatsapp_interactive.action.buttons must contain 1 to 3 buttons')

      resolved_buttons = buttons.map.with_index { |button, index| resolve_button(button, index, path) }
      titles = resolved_buttons.pluck('title')
      value!(titles.uniq.length == titles.length, 'whatsapp_interactive button titles must be unique')

      resolved = {
        'schema_version' => SCHEMA_VERSION,
        'type' => BUTTON_TYPE,
        'body' => { 'text' => body_text },
        'action' => { 'buttons' => resolved_buttons }
      }
      resolved['header'] = validated_header(interactive, path) if interactive.key?('header')
      resolved['footer'] = validated_footer(interactive, path) if interactive.key?('footer')
      resolved
    end

    def provider_payload(snapshot, attachment: nil)
      path = 'stored whatsapp_interactive'
      interactive = validated_interactive(snapshot, path)
      body_text = validated_body_text(interactive, path)
      buttons = validated_buttons(interactive, path)
      value!(BUTTON_COUNT_RANGE.cover?(buttons.length), 'stored whatsapp_interactive.action.buttons must contain 1 to 3 buttons')
      provider_buttons = buttons.map.with_index { |button, index| provider_button(button, index, path) }

      payload = {
        type: BUTTON_TYPE,
        body: { text: body_text },
        action: { buttons: provider_buttons }
      }
      payload[:header] = provider_header(interactive, path, attachment) if interactive.key?('header')
      payload[:footer] = { text: validated_footer(interactive, path)['text'] } if interactive.key?('footer')
      payload
    end

    def matching_media?(header_type, attachment)
      return false unless attachment&.file&.attached?

      expected_type = header_type == 'document' ? 'file' : header_type
      return false unless attachment.file_type == expected_type

      content_type = attachment.file.blob.content_type.to_s
      return !content_type.start_with?('image/', 'video/', 'audio/') if header_type == 'document'

      content_type.start_with?("#{header_type}/")
    end

    private

    def validated_interactive(payload, path)
      interactive = hash!(payload, path)
      exact_keys!(interactive, %w[schema_version type body action], path, optional: %w[header footer])
      value!(interactive['schema_version'] == SCHEMA_VERSION, "#{path}.schema_version must be 1")
      value!(interactive['type'] == BUTTON_TYPE, "#{path}.type must be button")
      interactive
    end

    def validated_body_text(interactive, path)
      body = hash!(interactive['body'], "#{path}.body")
      exact_keys!(body, %w[text], "#{path}.body")
      text!(body['text'], "#{path}.body.text", BODY_MAX_LENGTH)
    end

    def validated_header(interactive, path, stored: false)
      header_path = "#{path}.header"
      header = hash!(interactive['header'], header_path)
      value!(HEADER_TYPES.include?(header['type']), "#{header_path}.type must be text, image, video, or document")
      if header['type'] == 'text'
        exact_keys!(header, %w[type text], header_path)
        text!(header['text'], "#{header_path}.text", HEADER_MAX_LENGTH)
      else
        exact_keys!(header, stored ? %w[type attachment_id] : %w[type], header_path)
        if stored
          value!(header['attachment_id'].is_a?(Integer) && header['attachment_id'].positive?,
                 "#{header_path}.attachment_id must be a server attachment ID")
        end
      end
      header
    end

    def validated_footer(interactive, path)
      footer = hash!(interactive['footer'], "#{path}.footer")
      exact_keys!(footer, %w[text], "#{path}.footer")
      { 'text' => text!(footer['text'], "#{path}.footer.text", FOOTER_MAX_LENGTH) }
    end

    def provider_header(interactive, path, attachment)
      header = validated_header(interactive, path, stored: true)
      return { type: 'text', text: header['text'] } if header['type'] == 'text'

      value!(attachment && attachment.id == header['attachment_id'] && matching_media?(header['type'], attachment),
             "#{path}.header media is unavailable or mismatched")
      media = { link: attachment.download_url }
      media[:filename] = attachment.file.filename.to_s if header['type'] == 'document'
      { :type => header['type'], header['type'].to_sym => media }
    end

    def validated_buttons(interactive, path)
      action = hash!(interactive['action'], "#{path}.action")
      exact_keys!(action, %w[buttons], "#{path}.action")
      array!(action['buttons'], "#{path}.action.buttons")
    end

    def resolve_button(button, index, path)
      button_path = "#{path}.action.buttons[#{index}]"
      button = hash!(button, button_path)
      exact_keys!(button, %w[title], button_path)
      { 'delivery_id' => "reply_#{SecureRandom.uuid}", 'title' => text!(button['title'], "#{button_path}.title", BUTTON_TITLE_MAX_LENGTH) }
    end

    def provider_button(button, index, path)
      button_path = "#{path}.action.buttons[#{index}]"
      button = hash!(button, button_path)
      exact_keys!(button, %w[delivery_id title], button_path)
      delivery_id = text!(button['delivery_id'], "#{button_path}.delivery_id", 256)
      title = text!(button['title'], "#{button_path}.title", BUTTON_TITLE_MAX_LENGTH)
      { type: 'reply', reply: { id: delivery_id, title: title } }
    end

    def hash!(value, path)
      value!(value.is_a?(Hash) || value.is_a?(ActionController::Parameters), "#{path} must be an object")
      value.to_h.deep_stringify_keys
    end

    def array!(value, path)
      value!(value.is_a?(Array), "#{path} must be an array")
      value
    end

    def exact_keys!(value, expected, path, optional: [])
      keys = value.keys.map(&:to_s)
      unexpected = keys - expected - optional
      missing = expected - keys
      value!(unexpected.empty?, "#{path} contains unsupported fields: #{unexpected.join(', ')}")
      value!(missing.empty?, "#{path} is missing required fields: #{missing.join(', ')}")
    end

    def text!(value, path, maximum)
      value!(value.is_a?(String), "#{path} must be text")
      value!(value.present?, "#{path} cannot be blank")
      value!(value.length <= maximum, "#{path} must be #{maximum} characters or fewer")
      value
    end

    def value!(condition, message)
      raise Whatsapp::InteractiveMessages::ValidationError, message unless condition
    end
  end
end
