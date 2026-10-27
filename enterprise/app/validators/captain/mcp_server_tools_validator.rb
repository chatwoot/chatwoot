# Checks the tools an admin approved on an MCP server: their shape, names Captain can tell apart, and parameter sources.
class Captain::McpServerToolsValidator < ActiveModel::Validator
  SCHEMA = {
    'type': 'array',
    'items': {
      'type': 'object',
      'properties': {
        'name': { 'type': 'string', 'minLength': 1 },
        'approved_definition': {
          'type': 'object',
          'properties': {
            'description': { 'type': %w[string null] },
            'input_schema': { 'type': 'object' },
            # Captain uses read tools only, so a write tool can never be approved
            'read_only': { 'const': true }
          },
          'required': %w[input_schema read_only],
          'additionalProperties': false
        },
        'approved_digest': { 'type': 'string', 'pattern': '^sha256:[0-9a-f]{64}$' },
        'param_sources': {
          'type': 'object',
          'additionalProperties': {
            'oneOf': [
              {
                'type': 'object',
                'properties': { 'source': { 'const': Captain::McpServer::PARAM_SOURCE_VERIFIED_EMAIL } },
                'required': %w[source],
                'additionalProperties': false
              },
              {
                'type': 'object',
                'properties': { 'source': { 'const': Captain::McpServer::PARAM_SOURCE_FIXED }, 'value': { 'type': 'string', 'minLength': 1 } },
                'required': %w[source value],
                'additionalProperties': false
              }
            ]
          }
        },
        'settings': JSON.parse(Captain::CustomTool::SETTINGS_VALIDATION),
        'enabled': { 'type': 'boolean' }
      },
      'required': %w[name approved_definition approved_digest param_sources settings enabled],
      'additionalProperties': false
    }
  }.to_json.freeze

  def validate(server)
    JsonSchemaValidator.new(schema: SCHEMA, attribute_resolver: ->(record) { record.tools }).validate(server)

    tools = server.tools
    return unless tools.is_a?(Array) && tools.all?(Hash)

    names_error = tool_names_error(server, tools.pluck('name'))
    return server.errors.add(:tools, names_error) if names_error

    tools.each { |tool| validate_param_sources(server, tool) }
  end

  private

  def tool_names_error(server, names)
    return I18n.t('captain.mcp_server.tools.duplicate') if names.uniq.size != names.size

    # Captain names replace unsupported characters and cut long names, so two server names can become one
    clashing = names.group_by { |name| server.captain_tool_name(name) }.values.find { |group| group.size > 1 }
    I18n.t('captain.mcp_server.tools.name_clash', names: clashing.join(', ')) if clashing
  end

  def validate_param_sources(server, tool)
    properties = tool.dig('approved_definition', 'input_schema', 'properties') || {}
    sources = tool['param_sources'] || {}
    unknown = sources.keys - properties.keys
    return server.errors.add(:tools, I18n.t('captain.mcp_server.tools.unknown_param', tool: tool['name'], names: unknown.join(', '))) if unknown.any?

    validate_verified_email_param(server, tool['name'], sources, properties)
  end

  def validate_verified_email_param(server, tool_name, sources, properties)
    verified = sources.select { |_name, source| source['source'] == Captain::McpServer::PARAM_SOURCE_VERIFIED_EMAIL }.keys
    return server.errors.add(:tools, I18n.t('captain.mcp_server.tools.one_verified_email', tool: tool_name)) if verified.size > 1
    # Verified values are text, so a parameter that takes one must be a string
    return if verified.none? || properties.dig(verified.first, 'type') == 'string'

    server.errors.add(:tools, I18n.t('captain.mcp_server.tools.verified_email_type', tool: tool_name, name: verified.first))
  end
end
