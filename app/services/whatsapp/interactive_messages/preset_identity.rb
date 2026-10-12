class Whatsapp::InteractiveMessages::PresetIdentity
  class << self
    def for_save(definition, previous_definition: nil)
      normalized = normalized_preset(definition)
      return assign_fresh_ids(normalized) if previous_definition.blank?

      reconcile(normalized, previous_definition, unmatched: -> { { 'preset_option_id' => SecureRandom.uuid } })
    end

    def for_send(definition, preset:)
      normalized = normalized_preset(definition)
      unless normalized['type'] == preset.interactive_type
        raise Whatsapp::InteractiveMessages::ValidationError,
              'whatsapp_interactive type must match the source preset'
      end

      reconciled = reconcile(normalized, preset.definition, unmatched: -> { {} })
      reconciled['source'] = { 'preset_id' => preset.id }
      reconciled
    end

    private

    def normalized_preset(definition)
      payload = definition.respond_to?(:to_h) ? definition.to_h.deep_stringify_keys.deep_dup : definition
      payload.delete('source') if payload.is_a?(Hash)
      Whatsapp::InteractiveMessages::Registry.normalize_preset(payload, trusted_identity: true)
    end

    def assign_fresh_ids(definition)
      each_option(definition) { |_parent, option| option['preset_option_id'] = SecureRandom.uuid }
      definition
    end

    def reconcile(definition, previous_definition, unmatched:)
      authoritative = option_index(previous_definition)
      consumed = Set.new

      each_option(definition) do |parent, option|
        supplied_id = option['preset_option_id']
        previous = authoritative[[parent, supplied_id]]
        if supplied_id.present? && previous && consumed.exclude?(supplied_id) && owned_fields(option) == owned_fields(previous)
          consumed << supplied_id
        else
          option.delete('preset_option_id')
          option.merge!(unmatched.call)
        end
      end
      definition
    end

    def option_index(definition)
      index = {}
      each_option(definition.deep_stringify_keys) do |parent, option|
        option_id = option['preset_option_id']
        index[[parent, option_id]] = option if option_id.present?
      end
      index
    end

    def each_option(definition)
      option_groups(definition).each do |parent, options|
        options.each { |option| yield(parent, option) }
      end
    end

    def option_groups(definition)
      case definition['type']
      when Whatsapp::InteractiveMessages::Registry::BUTTON_TYPE
        [['button', definition.dig('action', 'buttons')]]
      when Whatsapp::InteractiveMessages::Registry::LIST_TYPE
        definition.dig('action', 'sections').map.with_index do |section, section_index|
          ["list:#{section_index}", section['rows']]
        end
      when Whatsapp::InteractiveMessages::Registry::CAROUSEL_TYPE
        definition.dig('action', 'cards').filter_map do |card|
          ["carousel:#{card['card_index']}", card.dig('action', 'buttons')] if card['type'] == Whatsapp::InteractiveMessages::Registry::BUTTON_TYPE
        end
      else
        []
      end
    end

    def owned_fields(option)
      option.slice('title', 'description')
    end
  end
end
