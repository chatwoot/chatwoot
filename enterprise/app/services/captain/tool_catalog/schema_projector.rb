class Captain::ToolCatalog::SchemaProjector
  def initialize(schema)
    @schema = schema
  end

  def project(value)
    projected = project_value(value, schema)
    return projected if JSONSchemer.schema(schema).valid?(projected)

    raise Captain::ToolCatalog::ExecutionError.new('invalid_response', 'response_schema_mismatch')
  end

  private

  attr_reader :schema

  def project_value(value, current_schema)
    current_schema = resolve_reference(current_schema)
    case current_schema['type']
    when 'object'
      project_object(value, current_schema)
    when 'array'
      project_array(value, current_schema)
    else
      value
    end
  end

  def resolve_reference(current_schema)
    reference = current_schema['$ref']
    return current_schema if reference.blank?
    raise invalid_schema_error unless reference.start_with?('#/')

    resolved = reference.delete_prefix('#/').split('/').reduce(schema) do |value, token|
      value.fetch(token.gsub('~1', '/').gsub('~0', '~'))
    end
    resolved.merge(current_schema.except('$ref'))
  rescue KeyError
    raise invalid_schema_error
  end

  def invalid_schema_error
    Captain::ToolCatalog::ExecutionError.new('invalid_response', 'invalid_output_schema')
  end

  def project_object(value, current_schema)
    return value unless value.is_a?(Hash)

    current_schema.fetch('properties', {}).each_with_object({}) do |(key, property_schema), result|
      next unless value.key?(key) || value.key?(key.to_sym)

      property_value = value.key?(key) ? value.fetch(key) : value.fetch(key.to_sym)
      result[key] = project_value(property_value, property_schema)
    end
  end

  def project_array(value, current_schema)
    return value unless value.is_a?(Array)

    value.first(current_schema.fetch('maxItems')).map do |item|
      project_value(item, current_schema.fetch('items', {}))
    end
  end
end
