class Captain::ToolCatalog::ProviderPackSourceLoader
  OperationSource = Data.define(:definition, :request)
  HTTP_METHODS = %w[get post].freeze

  def initialize(pack_path:)
    @pack_path = Pathname(pack_path).realpath
  end

  def load_operation(operation)
    case operation.fetch('source')
    when 'openapi'
      load_openapi_operation(operation.fetch('reference'))
    when 'graphql'
      OperationSource.new(
        definition: load_graphql_operation(operation.fetch('reference')),
        request: graphql_request(operation)
      )
    end
  end

  def load_schema(relative_path)
    schema = load_json(relative_path)
    JSONSchemer.schema(schema)
    schema
  rescue JSONSchemer::UnsupportedMetaSchema => e
    raise Captain::ToolCatalog::ProviderPackError, "Unsupported JSON Schema in #{relative_path}: #{e.message}"
  end

  def load_fixture(relative_path)
    load_json(relative_path)
  end

  def load_sources
    load_yaml('sources.yml')
  end

  private

  attr_reader :pack_path

  def graphql_request(operation)
    request = {
      'method' => 'POST',
      'encoding' => 'graphql',
      'parameters' => []
    }
    return request.merge('endpoint_strategy' => operation.fetch('endpoint_strategy')) if operation['endpoint_strategy'].present?

    request.merge('url' => operation.fetch('endpoint'))
  end

  def load_openapi_operation(reference)
    relative_path, pointer = reference.split('#', 2)
    invalid_pack!("OpenAPI reference must include a local JSON pointer: #{reference}") if pointer.blank?

    document = load_yaml(relative_path)
    path, method = openapi_request_target(pointer)
    operation = resolve_json_pointer(document, pointer)
    return openapi_operation_source(document, path, method, operation) if operation.is_a?(Hash)

    raise Captain::ToolCatalog::ProviderPackError, "OpenAPI reference does not resolve to an operation: #{reference}"
  end

  def openapi_request_target(pointer)
    tokens = json_pointer_tokens(pointer)
    valid = tokens.length == 3 && tokens.first == 'paths' && tokens.second.start_with?('/') && HTTP_METHODS.include?(tokens.third)
    invalid_pack!("OpenAPI reference must target a GET or POST operation: ##{pointer}") unless valid

    [tokens.second, tokens.third]
  end

  def openapi_operation_source(document, path, method, operation)
    path_item = document.dig('paths', path)
    server_url = fixed_server_url(operation, path_item, document)

    OperationSource.new(
      definition: operation,
      request: {
        'method' => method.upcase,
        'url' => "#{server_url.delete_suffix('/')}#{path}",
        'encoding' => method == 'get' ? 'query' : 'json',
        'parameters' => openapi_parameters(path_item, operation)
      }
    )
  end

  def openapi_parameters(path_item, operation)
    [*path_item.fetch('parameters', []), *operation.fetch('parameters', [])].map do |parameter|
      invalid_pack!('OpenAPI operation parameters must define a name and location') unless valid_openapi_parameter?(parameter)

      parameter.slice('name', 'in', 'required')
    end
  end

  def fixed_server_url(operation, path_item, document)
    servers = operation['servers'].presence || path_item['servers'].presence || document['servers']
    invalid_pack!('OpenAPI operations must resolve to exactly one fixed server') unless servers.is_a?(Array) && servers.one?

    server_url = servers.sole['url'] if servers.sole.is_a?(Hash)
    invalid_pack!('OpenAPI operations must resolve to exactly one fixed server') if server_url.blank?
    server_url
  end

  def valid_openapi_parameter?(parameter)
    parameter.is_a?(Hash) && parameter['name'].present? && parameter['in'].present?
  end

  def load_graphql_operation(reference)
    unless File.extname(reference) == '.graphql'
      raise Captain::ToolCatalog::ProviderPackError, "GraphQL operation must use a .graphql file: #{reference}"
    end

    operation = safe_path(reference).read.strip
    return operation if operation.present?

    raise Captain::ToolCatalog::ProviderPackError, "GraphQL operation is empty: #{reference}"
  end

  def load_yaml(relative_path)
    document = YAML.safe_load(safe_path(relative_path).read, aliases: false)
    return document if document.is_a?(Hash)

    raise Captain::ToolCatalog::ProviderPackError, "Provider Pack file must contain an object: #{relative_path}"
  rescue Psych::Exception => e
    raise Captain::ToolCatalog::ProviderPackError, "Provider Pack file is not valid YAML (#{relative_path}): #{e.message}"
  end

  def load_json(relative_path)
    document = JSON.parse(safe_path(relative_path).read)
    return document if document.is_a?(Hash)

    raise Captain::ToolCatalog::ProviderPackError, "Provider Pack JSON file must contain an object: #{relative_path}"
  rescue JSON::ParserError => e
    raise Captain::ToolCatalog::ProviderPackError, "Provider Pack file is not valid JSON (#{relative_path}): #{e.message}"
  end

  def safe_path(relative_path)
    path = Pathname(relative_path)
    invalid_pack!("Provider Pack references must be relative: #{relative_path}") if path.absolute?

    resolved_path = pack_path.join(path).realpath
    return resolved_path if resolved_path.to_s.start_with?("#{pack_path}/")

    raise Captain::ToolCatalog::ProviderPackError, "Provider Pack reference escapes its directory: #{relative_path}"
  rescue Errno::ENOENT
    raise Captain::ToolCatalog::ProviderPackError, "Provider Pack reference not found: #{relative_path}"
  end

  def resolve_json_pointer(document, pointer)
    invalid_pack!("Invalid local JSON pointer: ##{pointer}") unless pointer.start_with?('/')

    json_pointer_tokens(pointer).reduce(document) do |value, token|
      invalid_pack!("JSON pointer does not resolve: ##{pointer}") unless value.is_a?(Hash)

      value.fetch(token)
    end
  rescue KeyError
    raise Captain::ToolCatalog::ProviderPackError, "JSON pointer does not resolve: ##{pointer}"
  end

  def json_pointer_tokens(pointer)
    pointer.delete_prefix('/').split('/').map { |token| token.gsub('~1', '/').gsub('~0', '~') }
  end

  def invalid_pack!(message)
    raise Captain::ToolCatalog::ProviderPackError, message
  end
end
