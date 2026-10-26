# An MCP server connected to an assistant, with the tools an admin approved.
# Captain uses only approved read tools, and only while the live definition still matches the approved digest.
class Captain::McpServer < ApplicationRecord
  include Concerns::SafeEndpointValidatable

  self.table_name = 'captain_mcp_servers'

  FEATURE_FLAG = 'captain_mcp_servers'.freeze
  TOOL_NAME_PREFIX = 'mcp'.freeze
  # OpenAI function names allow these characters only, and at most 64 of them
  INVALID_TOOL_NAME_CHARACTERS = /[^a-zA-Z0-9_-]/
  MAX_TOOL_NAME_LENGTH = Captain::CustomTool::MAX_SLUG_LENGTH
  PARAM_SOURCE_VERIFIED_EMAIL = 'verified.email'.freeze
  PARAM_SOURCE_FIXED = 'fixed'.freeze
  TOOLS_VALIDATION = {
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
                'properties': { 'source': { 'const': PARAM_SOURCE_VERIFIED_EMAIL } },
                'required': %w[source],
                'additionalProperties': false
              },
              {
                'type': 'object',
                'properties': { 'source': { 'const': PARAM_SOURCE_FIXED }, 'value': { 'type': 'string', 'minLength': 1 } },
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

  belongs_to :account
  belongs_to :assistant, class_name: 'Captain::Assistant'
  # RubyLLM stores the OAuth tokens of this server with the server as their owner
  has_many :oauth_credentials, as: :owner, class_name: 'Captain::McpCredential', dependent: :delete_all

  enum :auth_type, %w[none oauth token].index_by(&:itself), prefix: :auth, validate: true
  enum :status, %w[active needs_sign_in error].index_by(&:itself), validate: true

  encrypts :auth_config if Chatwoot.encryption_configured?

  alias_attribute :endpoint_url, :url

  validates :url, presence: true, uniqueness: { scope: :assistant_id }
  validates :name, presence: true
  validates_with JsonSchemaValidator, schema: TOOLS_VALIDATION, attribute_resolver: ->(record) { record.tools }
  validate :validate_auth_header
  validate :validate_token
  validate :validate_tool_entries

  scope :enabled, -> { where(enabled: true) }

  # Keys are sorted first, so the same definition always has the same digest. The name is stored beside it.
  def self.definition_digest(definition)
    "sha256:#{Digest::SHA256.hexdigest(JSON.generate(sorted_keys(definition.deep_stringify_keys.except('name'))))}"
  end

  # The tool entry an admin approves, pinned to the live definition
  def self.approved_entry(definition, param_sources:, settings:, enabled:)
    {
      'name' => definition['name'],
      'approved_definition' => definition.except('name'),
      'approved_digest' => definition_digest(definition),
      'param_sources' => param_sources,
      'settings' => settings,
      'enabled' => enabled
    }
  end

  def self.sorted_keys(value)
    case value
    when Hash then value.sort.to_h.transform_values { |child| sorted_keys(child) }
    when Array then value.map { |child| sorted_keys(child) }
    else value
    end
  end
  private_class_method :sorted_keys

  # The name Captain sees. The server ID keeps names apart across servers, and the double underscore
  # keeps server 1's tool "2_x" apart from server 12's tool "x".
  def captain_tool_name(server_tool_name)
    "#{TOOL_NAME_PREFIX}_#{id}__#{server_tool_name.gsub(INVALID_TOOL_NAME_CHARACTERS, '_')}".first(MAX_TOOL_NAME_LENGTH)
  end

  # Approved tools Captain may use. The runtime still checks each digest against the live definition.
  def available_tools
    return [] unless enabled?

    tools.select { |tool| tool['enabled'] && tool.dig('approved_definition', 'read_only') }
  end

  def approved_tool(server_tool_name)
    tools.find { |tool| tool['name'] == server_tool_name }
  end

  def self.requires_email_verification?(tool)
    tool.dig('settings', 'requires_email_verification') == true || verified_email_param(tool).present?
  end

  def self.verified_email_param(tool)
    tool['param_sources'].find { |_name, source| source['source'] == PARAM_SOURCE_VERIFIED_EMAIL }&.first
  end

  private

  def validate_auth_header
    return if auth_header.nil?
    return errors.add(:auth_header, :invalid) unless Captain::CustomTool::HEADER_NAME_PATTERN.match?(auth_header)
    return unless Captain::CustomTool.reserved_header?(auth_header)

    errors.add(:auth_header, I18n.t('captain.custom_tool.headers.reserved', name: auth_header))
  end

  # The token is sent as a header value, so control characters would break the request
  def validate_token
    errors.add(:auth_config, :invalid) if auth_config['token'].to_s.match?(/[[:cntrl:]]/)
  end

  def validate_tool_entries
    return unless tools.is_a?(Array) && tools.all?(Hash)

    names = tools.pluck('name')
    errors.add(:tools, I18n.t('captain.mcp_server.tools.duplicate')) if names.uniq.size != names.size
    tools.each { |tool| validate_param_sources(tool) }
  end

  def validate_param_sources(tool)
    properties = tool.dig('approved_definition', 'input_schema', 'properties') || {}
    sources = tool['param_sources'] || {}
    unknown = sources.keys - properties.keys
    return errors.add(:tools, I18n.t('captain.mcp_server.tools.unknown_param', tool: tool['name'], names: unknown.join(', '))) if unknown.any?

    validate_verified_email_param(tool['name'], sources, properties)
  end

  def validate_verified_email_param(tool_name, sources, properties)
    verified = sources.select { |_name, source| source['source'] == PARAM_SOURCE_VERIFIED_EMAIL }.keys
    return errors.add(:tools, I18n.t('captain.mcp_server.tools.one_verified_email', tool: tool_name)) if verified.size > 1
    # Verified values are text, so a parameter that takes one must be a string
    return if verified.none? || properties.dig(verified.first, 'type') == 'string'

    errors.add(:tools, I18n.t('captain.mcp_server.tools.verified_email_type', tool: tool_name, name: verified.first))
  end
end
