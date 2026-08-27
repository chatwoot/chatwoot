class Captain::ToolsetService
  class InvalidManifestError < StandardError; end

  VERSION = 1
  KIND = 'captain_toolset'.freeze
  MAX_FILE_SIZE = 256.kilobytes
  VARIABLE_PATTERN = /\$\{\{\s*(inputs|secrets)\.([a-z][a-z0-9_]*)\s*\}\}/i
  VARIABLE_NAME_PATTERN = /\A[a-z][a-z0-9_]*\z/i
  ROOT_KEYS = %w[version kind name description inputs secrets tools].freeze
  CONFIG_KEYS = %w[label type placeholder required].freeze
  TOOL_KEYS = %w[title description endpoint_url http_method request_template response_template auth_type auth_config param_schema enabled].freeze

  def self.export(tool) = Captain::ToolsetExporter.new(tool).to_yaml

  def initialize(account:, source:)
    @account = account
    @manifest = parse(source)
  end

  def preview
    validate_manifest!
    validate_tools!(preview_configuration)

    {
      name: manifest['name'],
      description: manifest['description'],
      fields: configuration_fields,
      tools: tool_definitions.map { |tool| tool.slice('title', 'description', 'http_method', 'endpoint_url') }
    }
  end

  def import!(configuration)
    validate_manifest!
    raise InvalidManifestError, 'Toolset configuration must be an object' unless configuration.is_a?(Hash)

    configuration = configuration.deep_stringify_keys
    validate_configuration!(configuration)
    resolved_tools = resolve_tools(configuration)
    validate_tools!(configuration)
    ensure_capacity!(resolved_tools.size)

    ApplicationRecord.transaction do
      resolved_tools.map { |attributes| account.captain_custom_tools.create!(tool_attributes(attributes)) }
    end
  rescue ActiveRecord::RecordInvalid => e
    raise InvalidManifestError, e.record.errors.full_messages.join(', ')
  end

  private

  attr_reader :account, :manifest

  def parse(source)
    parsed = YAML.safe_load(source, permitted_classes: [], permitted_symbols: [], aliases: false)
    raise InvalidManifestError, 'Toolset must contain a YAML object' unless parsed.is_a?(Hash)

    parsed.deep_stringify_keys
  rescue Psych::Exception => e
    raise InvalidManifestError, "Invalid YAML: #{e.message}"
  end

  def validate_manifest!
    reject_unknown_keys!(manifest, ROOT_KEYS, 'toolset')
    validate_metadata!
    validate_tool_collection!
    validate_configuration_definitions!
    tool_definitions.each_with_index { |tool, index| validate_tool_definition!(tool, index) }
    validate_placeholders!
  end

  def validate_metadata!
    raise InvalidManifestError, "Toolset version must be #{VERSION}" unless manifest['version'] == VERSION
    raise InvalidManifestError, "Toolset kind must be #{KIND}" unless manifest['kind'] == KIND
    raise InvalidManifestError, 'Toolset name is required' if manifest['name'].blank?
  end

  def validate_tool_collection!
    raise InvalidManifestError, 'Tools must be a YAML list' unless manifest['tools'].is_a?(Array)
    raise InvalidManifestError, 'Toolset must contain at least one tool' if tool_definitions.empty?
    return unless tool_definitions.size > Captain::CustomTool::MAX_PER_ACCOUNT

    raise InvalidManifestError, "Toolset cannot contain more than #{Captain::CustomTool::MAX_PER_ACCOUNT} tools"
  end

  def validate_configuration_definitions!
    %w[inputs secrets].each do |section|
      definitions = manifest[section] || {}
      raise InvalidManifestError, "#{section.capitalize} must be a YAML object" unless definitions.is_a?(Hash)

      definitions.each do |name, definition|
        raise InvalidManifestError, "Invalid #{section.singularize} name: #{name}" unless name.match?(VARIABLE_NAME_PATTERN)
        raise InvalidManifestError, "Definition for #{name} must be a YAML object" unless definition.is_a?(Hash)

        reject_unknown_keys!(definition, CONFIG_KEYS, "#{section.singularize} #{name}")
      end
    end
  end

  def validate_tool_definition!(tool, index)
    raise InvalidManifestError, "Tool #{index + 1} must be a YAML object" unless tool.is_a?(Hash)

    reject_unknown_keys!(tool, TOOL_KEYS, "tool #{index + 1}")
  end

  def validate_placeholders!
    serialized_tools = tool_definitions.to_json
    serialized_tools.scan(VARIABLE_PATTERN).each do |section, name|
      next if manifest.fetch(section, {}).key?(name)

      raise InvalidManifestError, "Unknown #{section.singularize} placeholder: #{name}"
    end
  end

  def validate_configuration!(configuration)
    %w[inputs secrets].each do |section|
      values = configuration[section] || {}
      validate_configuration_section!(section, values)
    end
  end

  def validate_configuration_section!(section, values)
    raise InvalidManifestError, "#{section.capitalize} must be an object" unless values.is_a?(Hash)

    manifest.fetch(section, {}).each do |name, definition|
      next if !definition.fetch('required', true) || values[name].present?

      raise InvalidManifestError, "#{definition['label'].presence || name.humanize} is required"
    end
  end

  def validate_tools!(configuration)
    resolve_tools(configuration).each_with_index do |attributes, index|
      tool = account.captain_custom_tools.new(tool_attributes(attributes))
      next if tool.valid?

      raise InvalidManifestError, "#{tool_definitions[index]['title'].presence || "Tool #{index + 1}"}: #{tool.errors.full_messages.join(', ')}"
    end
  rescue ArgumentError, NoMethodError => e
    raise InvalidManifestError, "Invalid tool definition: #{e.message}"
  end

  def ensure_capacity!(tool_count)
    current_count = account.captain_custom_tools.count
    return if current_count + tool_count <= Captain::CustomTool::MAX_PER_ACCOUNT

    raise Captain::CustomTool::LimitExceededError,
          I18n.t('captain.custom_tool.limit_exceeded', limit: Captain::CustomTool::MAX_PER_ACCOUNT)
  end

  def resolve_tools(configuration) = interpolate(tool_definitions, configuration)

  def interpolate(value, configuration)
    case value
    when String
      interpolated = value.gsub(VARIABLE_PATTERN) do
        configuration.fetch(Regexp.last_match(1), {}).fetch(Regexp.last_match(2), '').to_s
      end
      raise InvalidManifestError, "Invalid placeholder: #{value}" if interpolated.include?('${{')

      interpolated
    when Array
      value.map { |item| interpolate(item, configuration) }
    when Hash
      value.transform_values { |item| interpolate(item, configuration) }
    else
      value
    end
  end

  def preview_configuration
    {
      'inputs' => manifest.fetch('inputs', {}).transform_values { |definition| definition['placeholder'].presence || 'preview' },
      'secrets' => manifest.fetch('secrets', {}).transform_values { 'preview' }
    }
  end

  def configuration_fields
    input_fields = manifest.fetch('inputs', {}).map { |name, definition| field_definition(name, definition, 'inputs', false) }
    secret_fields = manifest.fetch('secrets', {}).map { |name, definition| field_definition(name, definition, 'secrets', true) }
    input_fields + secret_fields
  end

  def field_definition(name, definition, section, secret)
    {
      name: name,
      label: definition['label'].presence || name.humanize,
      placeholder: definition['placeholder'],
      required: definition.fetch('required', true),
      section: section,
      secret: secret
    }
  end

  def tool_definitions = (@tool_definitions ||= manifest['tools'].is_a?(Array) ? manifest['tools'] : [])

  def tool_attributes(attributes)
    {
      title: attributes['title'],
      description: attributes['description'],
      endpoint_url: attributes['endpoint_url'],
      http_method: attributes['http_method'].presence || 'GET',
      request_template: attributes['request_template'],
      response_template: attributes['response_template'],
      auth_type: attributes['auth_type'].presence || 'none',
      auth_config: attributes['auth_config'] || {},
      param_schema: attributes['param_schema'] || [],
      enabled: attributes.fetch('enabled', true)
    }
  end

  def reject_unknown_keys!(object, allowed_keys, context)
    unknown_keys = object.keys - allowed_keys
    return if unknown_keys.empty?

    raise InvalidManifestError, "Unknown #{context} fields: #{unknown_keys.join(', ')}"
  end
end
