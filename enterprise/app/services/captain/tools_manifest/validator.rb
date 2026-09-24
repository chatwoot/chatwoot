# Validates a toolset.yml manifest against the Captain tools catalog schema and
# returns it with defaults applied. The rules mirror the catalog's manifest
# validator so any manifest the catalog accepts installs cleanly.
class Captain::ToolsManifest::Validator
  class InvalidManifestError < StandardError; end

  KIND = 'captain_toolset'.freeze
  MAX_BYTES = 256.kilobytes
  MAX_TOOLS = 50
  CATEGORIES = ['Commerce', 'Payments & billing', 'Shipping', 'CRM', 'Engineering & status', 'Scheduling',
                'Business data & research', 'Identity & access', 'Marketing', 'Others'].freeze
  DEFAULT_CATEGORY = 'Others'.freeze
  VERSION_PATTERN = /\A\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?\z/
  TOOL_ID_PATTERN = /\A[a-z][a-z0-9_]*\z/
  FIELD_NAME_PATTERN = /\A[a-z][a-z0-9_]*\z/i
  INSTALL_PLACEHOLDER_PATTERN = /\$\{\{\s*(inputs|secrets)\.([a-z][a-z0-9_]*)\s*\}\}/i
  CALL_PLACEHOLDER_PATTERN = /(?<!\$)\{\{\s*([A-Za-z_]\w*)/

  ROOT_KEYS = %w[version kind name description category headers inputs secrets tools].freeze
  FIELD_KEYS = %w[label type placeholder required options].freeze
  FIELD_TYPES = %w[string password number boolean select].freeze
  TOOL_KEYS = %w[id title description http_method endpoint_url auth_type auth_config param_schema
                 request_template response_template enabled].freeze
  REQUIRED_TOOL_TEXT_LIMITS = { 'title' => 100, 'description' => 500, 'endpoint_url' => 2000, 'auth_type' => 50 }.freeze
  TOOL_DEFAULTS = { 'auth_config' => {}, 'param_schema' => [], 'enabled' => true }.freeze
  AUTH_CONFIG_KEYS = { 'bearer' => %w[token], 'basic' => %w[username password], 'api_key' => %w[name key] }.freeze
  FIELD_DEFAULTS = { 'type' => 'string', 'required' => false }.freeze
  INSTALL_PLACEHOLDER_FIELDS = %w[endpoint_url auth_config request_template].freeze
  CALL_PLACEHOLDER_FIELDS = %w[endpoint_url request_template].freeze

  def initialize(source)
    @source = source
  end

  def perform
    ensure!(@source.bytesize <= MAX_BYTES, 'Manifest cannot be larger than 256 KiB')
    manifest = parse

    validate_metadata!(manifest)
    validate_headers!(manifest['headers'])
    %w[inputs secrets].each { |section| validate_fields!(manifest, section) }
    validate_tools!(manifest)

    normalize(manifest)
  end

  private

  def parse
    manifest = YAML.safe_load(@source, permitted_classes: [], permitted_symbols: [], aliases: false)
    ensure!(manifest.is_a?(Hash), 'Manifest must be a YAML object')

    manifest
  rescue Psych::Exception => e
    raise InvalidManifestError, "Invalid YAML: #{e.message}"
  end

  def validate_metadata!(manifest)
    reject_unknown_keys!(manifest, ROOT_KEYS, 'toolset')
    ensure!(manifest['version'].is_a?(String) && VERSION_PATTERN.match?(manifest['version']), 'version must be a semantic version')
    ensure!(manifest['kind'] == KIND, "kind must be #{KIND}")
    ensure!(text?(manifest['name'], 100), 'name must be 1-100 characters')
    ensure!(text?(manifest['description'], 500), 'description must be 1-500 characters')
    ensure!(manifest['category'].nil? || CATEGORIES.include?(manifest['category']), "category must be one of: #{CATEGORIES.join(', ')}")
  end

  def validate_headers!(headers)
    return if headers.nil?

    ensure!(headers.is_a?(Hash) && headers.keys.all?(String), 'headers must map header names to values')
    tool = Captain::CustomTool.new(headers: headers)
    tool.validate
    ensure!(tool.errors[:headers].empty?, tool.errors.full_messages_for(:headers).to_sentence)
  end

  def validate_fields!(manifest, section)
    fields = manifest[section]
    return if fields.nil?

    ensure!(fields.is_a?(Hash), "#{section} must be a YAML object")
    fields.each do |name, definition|
      ensure!(name.is_a?(String) && FIELD_NAME_PATTERN.match?(name), "Invalid #{section.singularize} name: #{name}")
      ensure!(definition.is_a?(Hash), "#{name} must be a YAML object")
      validate_field_definition!(name, definition, section)
    end
  end

  def validate_field_definition!(name, definition, section)
    reject_unknown_keys!(definition, FIELD_KEYS, "#{section.singularize} #{name}")
    ensure!(text?(definition['label'], 80), "#{name} label must be 1-80 characters")
    optional!(definition['type'], FIELD_TYPES.include?(definition['type']), "#{name} type must be one of: #{FIELD_TYPES.join(', ')}")
    optional!(definition['placeholder'], text?(definition['placeholder'], 200), "#{name} placeholder must be up to 200 characters")
    optional!(definition['required'], boolean?(definition['required']), "#{name} required must be true or false")
    optional!(definition['options'], list_of?(definition['options'], String), "#{name} options must be a list of strings")
  end

  def validate_tools!(manifest)
    tools = manifest['tools']
    ensure!(tools.is_a?(Array) && tools.size.between?(1, MAX_TOOLS), "Toolset must contain 1-#{MAX_TOOLS} tools")

    tools.each { |tool| validate_tool!(tool, manifest) }
    duplicate_id = tools.map { |tool| tool['id'] }.tally.find { |_, count| count > 1 }&.first
    ensure!(duplicate_id.nil?, "Duplicate tool id: #{duplicate_id}")
  end

  def validate_tool!(tool, manifest)
    ensure!(tool.is_a?(Hash), 'Each tool must be a YAML object')
    id = tool['id']
    ensure!(id.is_a?(String) && TOOL_ID_PATTERN.match?(id), "Invalid tool id: #{id}")
    reject_unknown_keys!(tool, TOOL_KEYS, "tool #{id}")
    validate_tool_fields!(tool, id)
    validate_install_placeholders!(tool, id, manifest)
    validate_call_placeholders!(tool, id)
    validate_liquid!(tool, id)
  end

  def validate_tool_fields!(tool, id)
    REQUIRED_TOOL_TEXT_LIMITS.each do |field, max_length|
      ensure!(text?(tool[field], max_length), "#{id} #{field} must be 1-#{max_length} characters")
    end
    http_methods = Captain::CustomTool.http_methods.keys
    ensure!(http_methods.include?(tool['http_method']), "#{id} http_method must be one of: #{http_methods.join(', ')}")
    validate_optional_tool_fields!(tool, id)
    validate_auth_config!(tool, id)
  end

  # Custom tools build auth headers from these keys, so a missing one only fails when the tool runs
  def validate_auth_config!(tool, id)
    required_keys = AUTH_CONFIG_KEYS.fetch(tool['auth_type'], [])
    present = required_keys.all? { |key| tool.dig('auth_config', key).is_a?(String) && tool.dig('auth_config', key).present? }
    ensure!(present, "#{id} auth_config must include #{required_keys.join(' and ')} for #{tool['auth_type']}")
  end

  def validate_optional_tool_fields!(tool, id)
    optional!(tool['auth_config'], tool['auth_config'].is_a?(Hash), "#{id} auth_config must be a YAML object")
    optional!(tool['param_schema'], list_of?(tool['param_schema'], Hash), "#{id} param_schema must be a list of YAML objects")
    optional!(tool['request_template'], text?(tool['request_template'], 20_000), "#{id} request_template must be 1-20000 characters")
    optional!(tool['response_template'], tool['response_template'].is_a?(String), "#{id} response_template must be a string")
    optional!(tool['enabled'], boolean?(tool['enabled']), "#{id} enabled must be true or false")
  end

  def validate_install_placeholders!(tool, id, manifest)
    (tool.keys - INSTALL_PLACEHOLDER_FIELDS).each do |field|
      ensure!(tool[field].to_json.exclude?('${{'), "#{id} #{field} cannot contain install-time placeholders")
    end

    INSTALL_PLACEHOLDER_FIELDS.each do |field|
      value = tool[field].to_json
      value.scan(INSTALL_PLACEHOLDER_PATTERN).each do |section, name|
        ensure!(manifest[section.downcase]&.key?(name), "#{id} #{field} uses undeclared placeholder #{section}.#{name}")
      end
      ensure!(value.gsub(INSTALL_PLACEHOLDER_PATTERN, '').exclude?('${{'), "#{id} #{field} has an invalid install-time placeholder")
    end
  end

  def validate_call_placeholders!(tool, id)
    param_names = Array(tool['param_schema']).pluck('name')
    CALL_PLACEHOLDER_FIELDS.each do |field|
      tool[field].to_s.scan(CALL_PLACEHOLDER_PATTERN).flatten.each do |name|
        ensure!(param_names.include?(name), "#{id} #{field} uses undeclared parameter #{name}")
      end
    end
  end

  def validate_liquid!(tool, id)
    return if tool['response_template'].blank?

    Liquid::Template.parse(tool['response_template'], error_mode: :strict)
  rescue Liquid::SyntaxError => e
    raise InvalidManifestError, "#{id} response_template is not valid Liquid: #{e.message}"
  end

  def normalize(manifest)
    manifest.merge(
      'category' => manifest['category'] || DEFAULT_CATEGORY,
      'headers' => manifest['headers'] || {},
      'inputs' => normalize_fields(manifest['inputs']),
      'secrets' => normalize_fields(manifest['secrets']),
      'tools' => manifest['tools'].map { |tool| TOOL_DEFAULTS.merge(tool.compact) }
    )
  end

  def normalize_fields(fields)
    (fields || {}).transform_values { |definition| FIELD_DEFAULTS.merge(definition.compact) }
  end

  def reject_unknown_keys!(object, allowed_keys, context)
    unknown_keys = object.keys - allowed_keys
    ensure!(unknown_keys.empty?, "Unknown #{context} fields: #{unknown_keys.join(', ')}")
  end

  def text?(value, max_length)
    value.is_a?(String) && value.length.between?(1, max_length)
  end

  def list_of?(value, type)
    value.is_a?(Array) && value.all?(type)
  end

  def boolean?(value)
    [true, false].include?(value)
  end

  def optional!(value, valid, message)
    ensure!(value.nil? || valid, message)
  end

  def ensure!(condition, message)
    raise InvalidManifestError, message unless condition
  end
end
