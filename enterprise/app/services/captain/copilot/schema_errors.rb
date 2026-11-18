# Readable messages for JSON schema errors, so the model sees which argument or filter is wrong and what it must be,
# instead of a list of everything allowed.
module Captain::Copilot::SchemaErrors
  TYPES = %w[string integer number boolean array object null].freeze

  def self.messages(schema, data)
    JSONSchemer.schema(schema.deep_stringify_keys).validate(data.deep_stringify_keys).map { |error| message(error) }
  end

  def self.message(error)
    field = field_name(error)
    case error['type']
    when 'required' then "missing #{Array(error.dig('details', 'missing_keys')).join(', ')}"
    when 'schema' then "#{field} is not allowed here"
    when 'enum' then "#{field} must be one of #{error.dig('schema', 'enum').map { |value| value || 'null' }.join(', ')}"
    when *TYPES then "#{field} must be #{Array(error.dig('schema', 'type')).join(' or ')}"
    else "#{field} fails #{error['type']} #{error.dig('schema', error['type'])}".strip
    end
  end

  def self.field_name(error)
    error['data_pointer'].delete_prefix('/').tr('/', '.').presence || 'the value'
  end
end
