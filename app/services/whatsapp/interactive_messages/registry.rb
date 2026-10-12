class Whatsapp::InteractiveMessages::Registry
  SCHEMA_VERSION = 1
  BUTTON_TYPE = 'button'.freeze
  BODY_MAX_LENGTH = 1024
  BUTTON_TITLE_MAX_LENGTH = 20
  BUTTON_COUNT_RANGE = (1..3)

  class << self
    def limits
      {
        body_max_length: BODY_MAX_LENGTH,
        button_title_max_length: BUTTON_TITLE_MAX_LENGTH,
        button_min_count: BUTTON_COUNT_RANGE.min,
        button_max_count: BUTTON_COUNT_RANGE.max
      }
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

      {
        'schema_version' => SCHEMA_VERSION,
        'type' => BUTTON_TYPE,
        'body' => { 'text' => body_text },
        'action' => { 'buttons' => resolved_buttons }
      }
    end

    def provider_payload(snapshot)
      path = 'stored whatsapp_interactive'
      interactive = validated_interactive(snapshot, path)
      body_text = validated_body_text(interactive, path)
      buttons = validated_buttons(interactive, path)
      value!(BUTTON_COUNT_RANGE.cover?(buttons.length), 'stored whatsapp_interactive.action.buttons must contain 1 to 3 buttons')
      provider_buttons = buttons.map.with_index { |button, index| provider_button(button, index, path) }

      {
        type: BUTTON_TYPE,
        body: { text: body_text },
        action: { buttons: provider_buttons }
      }
    end

    private

    def validated_interactive(payload, path)
      interactive = hash!(payload, path)
      exact_keys!(interactive, %w[schema_version type body action], path)
      value!(interactive['schema_version'] == SCHEMA_VERSION, "#{path}.schema_version must be 1")
      value!(interactive['type'] == BUTTON_TYPE, "#{path}.type must be button")
      interactive
    end

    def validated_body_text(interactive, path)
      body = hash!(interactive['body'], "#{path}.body")
      exact_keys!(body, %w[text], "#{path}.body")
      text!(body['text'], "#{path}.body.text", BODY_MAX_LENGTH)
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

    def exact_keys!(value, expected, path)
      keys = value.keys.map(&:to_s)
      unexpected = keys - expected
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
