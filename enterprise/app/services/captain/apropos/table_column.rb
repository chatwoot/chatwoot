class Captain::Apropos::TableColumn
  TYPES = %w[text number datetime status tags conversation contact].freeze
  LINKS = %w[conversation contact].freeze
  VALIDATORS = {
    'number' => ->(value) { value.is_a?(Integer) || (value.is_a?(Float) && value.finite?) },
    'tags' => ->(value) { value.is_a?(Array) && value.all?(String) },
    'status' => ->(value) { %w[open resolved pending snoozed].include?(value) },
    'datetime' => ->(value) { value.is_a?(String) && value.match?(/(?:Z|[+-]\d{2}:\d{2})\z/) && Time.iso8601(value) }
  }.freeze

  def self.normalize(value)
    value = { 'key' => value } if value.is_a?(String)
    validate_shape!(value)
    column = { 'type' => 'text' }.merge(value)
    unless column.key?('key') && TYPES.include?(column['type'])
      raise Captain::Apropos::Error, "show-table column requires key and a supported type: #{TYPES.join(', ')}"
    end

    if LINKS.include?(column['type']) != column.key?('id_key')
      raise Captain::Apropos::Error, 'show-table id_key is required for conversation/contact columns and forbidden for other types'
    end

    column
  end

  def self.validate_shape!(value)
    unless value.is_a?(Hash) && (value.keys - %w[key label type id_key]).empty? &&
           value.values.all? { |item| item.is_a?(String) && item.strip.present? }
      raise Captain::Apropos::Error, 'show-table column expects a field name or {key, label?, type?, id_key?} with nonblank strings'
    end
  end

  def self.valid_cell?(value, type)
    return true if value.nil?

    return VALIDATORS.fetch(type).call(value) if VALIDATORS.key?(type)

    value.is_a?(String) || value == true || value == false || VALIDATORS.fetch('number').call(value)
  rescue ArgumentError
    false
  end
end
