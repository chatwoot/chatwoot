require 'uri'

class Captain::ToolCatalog::ProviderPackValidator
  SHOPIFY_DYNAMIC_ORIGIN = 'https://*.myshopify.com'.freeze
  SERVER_BINDING_PATHS = {
    'contact' => %w[id email phone_number],
    'conversation' => %w[id display_id]
  }.freeze
  SECRET_PATTERNS = [
    /\b(?:sk|rk)_(?:live|test)_[A-Za-z0-9]{16,}\b/,
    /\bxox[baprs]-[A-Za-z0-9-]{16,}\b/,
    /\bBearer\s+[A-Za-z0-9._-]{16,}\b/i,
    /-----BEGIN [A-Z ]*PRIVATE KEY-----/
  ].freeze
  SECRET_CONFIGURATION_KEY = /(?:password|secret|token|api[_-]?key|credential|private[_-]?key)/i
  SOURCES_SCHEMA_PATH = Rails.root.join(
    'enterprise/config/captain/tool_catalog/provider_pack_sources_schema.json'
  ).freeze

  def validate_manifest!(manifest)
    ensure_unique_keys!('category', manifest.fetch('categories'))
    ensure_unique_keys!('operation', manifest.fetch('operations'))
    ensure_unique_keys!('template', manifest.fetch('templates'))
  end

  def validated_origins(origins)
    origins.map { |origin| validate_origin!(origin) }.sort
  end

  def validate_sources!(sources)
    validate_schema!(sources, SOURCES_SCHEMA_PATH, 'sources.yml')
    reject_secret_literals!(sources, 'sources.yml')
  end

  def validate_operation_request!(request, allowed_origins, provider_key:)
    runtime_validator.validate_operation_request!(request, allowed_origins, provider_key: provider_key)
  end

  def validate_configuration_schema!(schema, location)
    unless schema['type'] == 'object' && schema['additionalProperties'] == false
      raise Captain::ToolCatalog::ProviderPackError,
            "Configuration schema must be a closed object: #{location}"
    end

    invalid_object = object_schemas(schema).find { |object_schema| object_schema['additionalProperties'] != false }
    if invalid_object
      raise Captain::ToolCatalog::ProviderPackError,
            "Configuration object schemas must reject additional properties: #{location}"
    end

    secret_keys = object_schemas(schema).flat_map { |object_schema| object_schema.fetch('properties', {}).keys }
                                        .grep(SECRET_CONFIGURATION_KEY)
    return if secret_keys.empty?

    raise Captain::ToolCatalog::ProviderPackError,
          "Configuration schema contains credential fields: #{secret_keys.uniq.sort.join(', ')}"
  end

  def validate_schema_references!(schema, location)
    external_references = schema_references(schema).reject { |reference| reference.start_with?('#/') }
    return if external_references.empty?

    raise Captain::ToolCatalog::ProviderPackError,
          "Schema contains an external reference: #{location}"
  end

  def validate_model_input_schema!(schema, location)
    runtime_validator.validate_model_input_schema!(schema, location)
  end

  def validate_output_schema!(schema, location)
    runtime_validator.validate_output_schema!(schema, location)
  end

  def validate_binding!(binding, provider_key:, step_index:, input_schema:, configuration_schema:)
    source = binding.fetch('source')
    provider_binding = Captain::ToolCatalog::ProviderBindingValidator.new
    return if provider_binding.validate!(binding, provider_key: provider_key, step_index: step_index, input_schema: input_schema)

    validate_binding_shape!(binding, source)
    return validate_server_binding!(binding, source) if SERVER_BINDING_PATHS.key?(source)

    send("validate_#{source}_binding!", binding, step_index, input_schema, configuration_schema)
  end

  def validate_template_availability!(template, risk_class)
    approval_required = template.fetch('availability') == 'approval_required'
    return if approval_required == (risk_class == 'approval_required')

    raise Captain::ToolCatalog::ProviderPackError,
          "Template availability and risk disagree: #{template.fetch('key')}"
  end

  def reject_secret_literals!(value, location)
    child_values(value).each { |child| reject_secret_literals!(child, location) }
    return unless secret_literal?(value)

    raise Captain::ToolCatalog::ProviderPackError, "Provider Pack contains a secret literal: #{location}"
  end

  private

  def ensure_unique_keys!(kind, entries)
    duplicate_keys = entries.group_by { |entry| entry.fetch('key') }.select { |_key, values| values.many? }.keys
    return if duplicate_keys.empty?

    raise Captain::ToolCatalog::ProviderPackError, "Duplicate #{kind} keys: #{duplicate_keys.sort.join(', ')}"
  end

  def validate_origin!(origin)
    return origin if origin == SHOPIFY_DYNAMIC_ORIGIN

    validate_exact_origin!(origin)
  end

  def validate_exact_origin!(origin)
    uri = URI.parse(origin)
    raise_origin_error(origin) unless uri.scheme == 'https'
    raise_origin_error(origin) if uri.host.blank? || uri.userinfo.present?

    canonical_origin = "https://#{uri.host}"
    canonical_origin += ":#{uri.port}" unless uri.port == 443
    raise_origin_error(origin) unless origin == canonical_origin

    origin
  rescue URI::InvalidURIError
    raise Captain::ToolCatalog::ProviderPackError, "Provider origin is invalid: #{origin}"
  end

  def raise_origin_error(origin)
    raise Captain::ToolCatalog::ProviderPackError, "Provider origin must be an exact HTTPS origin: #{origin}"
  end

  def validate_binding_shape!(binding, source)
    return validate_literal_shape!(binding) if source == 'literal'
    return if source == 'step_output' && !binding.key?('value')
    return unless binding.key?('step') || binding.key?('value')

    raise Captain::ToolCatalog::ProviderPackError, "Unexpected fields for #{source} binding"
  end

  def validate_literal_shape!(binding)
    return unless binding.key?('path') || binding.key?('step')

    raise Captain::ToolCatalog::ProviderPackError, 'Literal bindings may contain only source and value'
  end

  def validate_server_binding!(binding, source)
    path = binding.fetch('path')
    return if SERVER_BINDING_PATHS.fetch(source).include?(path)

    raise Captain::ToolCatalog::ProviderPackError, "Unsupported #{source} binding: #{path}"
  end

  def validate_model_input_binding!(binding, _step_index, input_schema, _configuration_schema)
    validate_schema_binding!(binding, input_schema, 'model_input')
  end

  def validate_configuration_binding!(binding, _step_index, _input_schema, configuration_schema)
    validate_schema_binding!(binding, configuration_schema, 'configuration')
  end

  def validate_step_output_binding!(binding, step_index, _input_schema, _configuration_schema)
    referenced_step = binding.fetch('step')
    return if referenced_step < step_index

    raise Captain::ToolCatalog::ProviderPackError,
          "Recipe step #{step_index} cannot read step #{referenced_step}"
  end

  def validate_literal_binding!(binding, _step_index, _input_schema, _configuration_schema)
    reject_secret_literals!(binding.fetch('value'), 'literal binding')
  end

  def validate_schema_binding!(binding, schema, source)
    root_property = binding.fetch('path').split('.').first
    return if schema.fetch('properties', {}).key?(root_property)

    raise Captain::ToolCatalog::ProviderPackError, "Unknown #{source} binding: #{binding.fetch('path')}"
  end

  def validate_schema!(value, schema_path, label)
    validation_errors = JSONSchemer.schema(JSON.parse(schema_path.read)).validate(value).to_a
    return if validation_errors.empty?

    errors = validation_errors.map { |error| "#{error['data_pointer'].presence || '/'} #{error['type']}" }
    raise Captain::ToolCatalog::ProviderPackError, "Invalid #{label}: #{errors.sort.join(', ')}"
  end

  def child_values(value)
    return value.each_value if value.is_a?(Hash)
    return value.each if value.is_a?(Array)

    []
  end

  def object_schemas(value)
    return [] unless value.is_a?(Hash)

    schemas = value['type'] == 'object' ? [value] : []
    schemas + value.values.flat_map do |child|
      if child.is_a?(Array)
        child.flat_map { |item| object_schemas(item) }
      else
        object_schemas(child)
      end
    end
  end

  def schema_references(value)
    return [] unless value.is_a?(Hash)

    references = value['$ref'].present? ? [value['$ref']] : []
    references + value.values.flat_map do |child|
      child.is_a?(Array) ? child.flat_map { |item| schema_references(item) } : schema_references(child)
    end
  end

  def runtime_validator
    @runtime_validator ||= Captain::ToolCatalog::ProviderPackRuntimeValidator.new
  end

  def secret_literal?(value)
    value.is_a?(String) && SECRET_PATTERNS.any? { |pattern| value.match?(pattern) }
  end
end
