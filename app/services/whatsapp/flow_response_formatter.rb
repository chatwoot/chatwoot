class Whatsapp::FlowResponseFormatter
  HIDDEN_KEYS = %w[flow_token].freeze
  HIDDEN_KEY_PATTERN = /password|passcode|otp|secret/i

  class << self
    def parse_response_json(message)
      raw = message.dig(:interactive, :nfm_reply, :response_json) ||
            message.dig('interactive', 'nfm_reply', 'response_json')
      return {} if raw.blank?

      parsed = raw.is_a?(String) ? JSON.parse(raw) : raw
      parsed.is_a?(Hash) ? parsed.deep_stringify_keys : {}
    rescue JSON::ParserError
      {}
    end

    def nfm_reply?(message)
      type = message.dig(:interactive, :type) || message.dig('interactive', 'type')
      type.to_s == 'nfm_reply'
    end

    def visible_entries(payload)
      flatten_payload(payload).reject { |key, value| hide_key?(key) || value.blank? }
    end

    def format_details(payload)
      visible_entries(payload).map { |key, value| "• #{humanize_key(key)}: #{value}" }.join("\n")
    end

    def format_for_agent(payload)
      details = format_details(payload)
      return I18n.t('conversations.messages.whatsapp.flow_response.empty') if details.blank?

      I18n.t('conversations.messages.whatsapp.flow_response.received', details: details)
    end

    def format_confirmation(payload)
      details = format_details(payload)
      if details.blank?
        return I18n.t('conversations.messages.whatsapp.flow_confirmation.empty')
      end

      [
        I18n.t('conversations.messages.whatsapp.flow_confirmation.header'),
        details,
        I18n.t('conversations.messages.whatsapp.flow_confirmation.footer')
      ].join("\n\n")
    end

    private

    def hide_key?(key)
      HIDDEN_KEYS.include?(key.to_s) || key.to_s.match?(HIDDEN_KEY_PATTERN)
    end

    def humanize_key(key)
      key.to_s.tr('_', ' ').strip.capitalize
    end

    def flatten_payload(payload, prefix = nil)
      return {} unless payload.is_a?(Hash)

      payload.each_with_object({}) do |(key, value), result|
        full_key = prefix ? "#{prefix}.#{key}" : key.to_s
        case value
        when Hash
          result.merge!(flatten_payload(value, full_key))
        when Array
          result[full_key] = value.map(&:to_s).reject(&:blank?).join(', ')
        else
          result[full_key] = value.to_s.strip
        end
      end
    end
  end
end
