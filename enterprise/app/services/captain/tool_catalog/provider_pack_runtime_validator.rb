require 'uri'

class Captain::ToolCatalog::ProviderPackRuntimeValidator
  ENDPOINT_STRATEGY_ORIGINS = {
    'shopify_admin_graphql' => Captain::ToolCatalog::ProviderPackValidator::SHOPIFY_DYNAMIC_ORIGIN
  }.freeze
  UNSUPPORTED_PROJECTION_KEYWORDS = %w[allOf anyOf oneOf if then else not patternProperties].freeze

  def validate_operation_request!(request, allowed_origins, provider_key:)
    return validate_endpoint_strategy!(request, allowed_origins, provider_key) if request['endpoint_strategy'].present?

    uri = parse_url(request.fetch('url'))
    validate_fixed_url!(uri, request.fetch('url'), allowed_origins)
    validate_parameter_locations!(request.fetch('parameters'))
  end

  def validate_model_input_schema!(schema, location)
    validate_closed_object_schema!(schema, location, 'Model input')
    validate_bounded_arrays!(schema, location)
    validate_safe_field_names!(schema, location, 'Model input')
  end

  def validate_output_schema!(schema, location)
    validate_closed_object_schema!(schema, location, 'Output')
    validate_bounded_arrays!(schema, location)
    validate_safe_field_names!(schema, location, 'Output')
    validate_projection_shape!(schema, location)
  end

  private

  def validate_endpoint_strategy!(request, allowed_origins, provider_key)
    expected_origin = ENDPOINT_STRATEGY_ORIGINS[request.fetch('endpoint_strategy')]
    return if provider_key == 'shopify' && expected_origin.present? && allowed_origins.include?(expected_origin)

    raise Captain::ToolCatalog::ProviderPackError, 'Operation endpoint strategy is not allowed by the provider'
  end

  def parse_url(url)
    normalized_url = url.gsub(/\{[a-zA-Z0-9_]+\}/, 'path-parameter')
    raise URI::InvalidURIError if normalized_url.match?(/[{}]/)

    URI.parse(normalized_url)
  rescue URI::InvalidURIError
    raise Captain::ToolCatalog::ProviderPackError, "Operation URL is invalid: #{url}"
  end

  def validate_fixed_url!(uri, url, allowed_origins)
    return if fixed_https_url?(uri) && allowed_origins.include?(origin_for(uri))

    raise Captain::ToolCatalog::ProviderPackError, "Operation URL is outside the provider allowlist: #{url}"
  end

  def fixed_https_url?(uri)
    uri.scheme == 'https' && uri.host.present? && uri.userinfo.blank? && uri.query.blank? && uri.fragment.blank?
  end

  def origin_for(uri)
    origin = "#{uri.scheme}://#{uri.host}"
    uri.port == 443 ? origin : "#{origin}:#{uri.port}"
  end

  def validate_parameter_locations!(parameters)
    unsupported = parameters.pluck('in').compact - %w[path query]
    return if unsupported.empty?

    raise Captain::ToolCatalog::ProviderPackError,
          "Operation parameters use unsupported locations: #{unsupported.uniq.sort.join(', ')}"
  end

  def validate_closed_object_schema!(schema, location, label)
    invalid = schema['type'] != 'object' || object_schemas(schema).any? { |object_schema| object_schema['additionalProperties'] != false }
    return unless invalid

    raise Captain::ToolCatalog::ProviderPackError, "#{label} schema must contain closed objects only: #{location}"
  end

  def validate_bounded_arrays!(schema, location)
    invalid = schemas_of_type(schema, 'array').find do |array_schema|
      !array_schema['maxItems'].is_a?(Integer) || !array_schema['maxItems'].between?(1, 10)
    end
    return if invalid.blank?

    raise Captain::ToolCatalog::ProviderPackError, "Schema arrays must set maxItems between 1 and 10: #{location}"
  end

  def validate_safe_field_names!(schema, location, label)
    sensitive_fields = object_schemas(schema)
                       .flat_map { |object_schema| object_schema.fetch('properties', {}).keys }
                       .grep(Captain::ToolCatalog::ProviderPackValidator::SECRET_CONFIGURATION_KEY)
    return if sensitive_fields.empty?

    raise Captain::ToolCatalog::ProviderPackError,
          "#{label} schema contains credential fields (#{sensitive_fields.uniq.sort.join(', ')}): #{location}"
  end

  def validate_projection_shape!(schema, location)
    unsupported = schema_hashes(schema).flat_map { |entry| entry.keys & UNSUPPORTED_PROJECTION_KEYWORDS }.uniq.sort
    invalid_array = schemas_of_type(schema, 'array').any? { |array_schema| !array_schema['items'].is_a?(Hash) }
    return if unsupported.empty? && !invalid_array

    raise Captain::ToolCatalog::ProviderPackError, "Output schema is not projection-safe: #{location}"
  end

  def object_schemas(schema)
    schemas_of_type(schema, 'object')
  end

  def schemas_of_type(value, type)
    return [] unless value.is_a?(Hash)

    schemas = value['type'] == type ? [value] : []
    schemas + value.values.flat_map do |child|
      child.is_a?(Array) ? child.flat_map { |item| schemas_of_type(item, type) } : schemas_of_type(child, type)
    end
  end

  def schema_hashes(value)
    return [] unless value.is_a?(Hash)

    [value] + value.values.flat_map do |child|
      child.is_a?(Array) ? child.flat_map { |item| schema_hashes(item) } : schema_hashes(child)
    end
  end
end
