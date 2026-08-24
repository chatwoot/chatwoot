class Captain::ToolCatalog::ProviderPackSourceLoader
  def initialize(pack_path:)
    @pack_path = Pathname(pack_path).realpath
  end

  def load_operation(operation)
    case operation.fetch('source')
    when 'openapi'
      load_openapi_operation(operation.fetch('reference'))
    when 'graphql'
      load_graphql_operation(operation.fetch('reference'))
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

  def load_openapi_operation(reference)
    relative_path, pointer = reference.split('#', 2)
    invalid_pack!("OpenAPI reference must include a local JSON pointer: #{reference}") if pointer.blank?

    operation = resolve_json_pointer(load_yaml(relative_path), pointer)
    return operation if operation.is_a?(Hash)

    raise Captain::ToolCatalog::ProviderPackError, "OpenAPI reference does not resolve to an operation: #{reference}"
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

    pointer.delete_prefix('/').split('/').reduce(document) do |value, token|
      invalid_pack!("JSON pointer does not resolve: ##{pointer}") unless value.is_a?(Hash)

      value.fetch(token.gsub('~1', '/').gsub('~0', '~'))
    end
  rescue KeyError
    raise Captain::ToolCatalog::ProviderPackError, "JSON pointer does not resolve: ##{pointer}"
  end

  def invalid_pack!(message)
    raise Captain::ToolCatalog::ProviderPackError, message
  end
end
