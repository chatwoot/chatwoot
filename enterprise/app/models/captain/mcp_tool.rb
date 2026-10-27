# A tool on an MCP server that an admin approved for Captain, pinned to the definition the admin reviewed.
# Captain uses it only while the server's live definition still matches approved_digest.
class Captain::McpTool < ApplicationRecord
  self.table_name = 'captain_mcp_tools'

  PARAM_SOURCE_VERIFIED_EMAIL = 'verified.email'.freeze
  PARAM_SOURCE_FIXED = 'fixed'.freeze
  APPROVED_DEFINITION_VALIDATION = {
    'type': 'object',
    'properties': {
      'description': { 'type': %w[string null] },
      'input_schema': { 'type': 'object' },
      # Captain uses read tools only, so a write tool can never be approved
      'read_only': { 'const': true }
    },
    'required': %w[input_schema read_only],
    'additionalProperties': false
  }.to_json.freeze
  PARAM_SOURCES_VALIDATION = {
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
  }.to_json.freeze

  belongs_to :account
  belongs_to :mcp_server, class_name: 'Captain::McpServer'

  # Set once, so scenarios that reference the tool keep working if the naming rule changes later
  before_validation :assign_captain_name, on: :create

  validates :name, presence: true, uniqueness: { scope: :mcp_server_id }
  validates :approved_digest, format: { with: /\Asha256:[0-9a-f]{64}\z/ }
  validates_with JsonSchemaValidator,
                 schema: APPROVED_DEFINITION_VALIDATION,
                 attribute_resolver: ->(record) { record.approved_definition }
  validates_with JsonSchemaValidator,
                 schema: PARAM_SOURCES_VALIDATION,
                 attribute_resolver: ->(record) { record.param_sources }
  validates_with JsonSchemaValidator,
                 schema: Captain::CustomTool::SETTINGS_VALIDATION,
                 attribute_resolver: ->(record) { record.settings }
  validate :validate_captain_name
  validate :validate_param_sources

  # Keys are sorted first, so the same definition always has the same digest. The name is stored beside it.
  def self.definition_digest(definition)
    "sha256:#{Digest::SHA256.hexdigest(JSON.generate(sorted_keys(definition.deep_stringify_keys.except('name'))))}"
  end

  def self.sorted_keys(value)
    case value
    when Hash then value.sort.to_h.transform_values { |child| sorted_keys(child) }
    when Array then value.map { |child| sorted_keys(child) }
    else value
    end
  end
  private_class_method :sorted_keys

  # Pins the tool to a live definition the admin reviewed
  def approve(definition)
    self.approved_definition = definition.except('name')
    self.approved_digest = self.class.definition_digest(definition)
  end

  def approval_current?(live_definition)
    approved_digest == self.class.definition_digest(live_definition)
  end

  def description
    approved_definition['description']
  end

  def input_schema
    approved_definition['input_schema']
  end

  def requires_email_verification?
    settings['requires_email_verification'] == true || verified_email_param.present?
  end

  def verified_email_param
    param_sources.find { |_name, source| source['source'] == PARAM_SOURCE_VERIFIED_EMAIL }&.first
  end

  private

  def assign_captain_name
    self.captain_name ||= mcp_server&.captain_tool_name(name.to_s)
  end

  # Captain names replace unsupported characters and cut long names, so two server names can become one.
  # The unique index keeps that true under concurrent saves; this check gives the admin a readable error.
  def validate_captain_name
    clash = self.class.where(captain_name: captain_name).where.not(id: id).first
    errors.add(:name, I18n.t('captain.mcp_server.tools.name_clash', names: [clash.name, name].join(', '))) if clash
  end

  # The schema checks above guarantee the shapes read here, so this runs only once they pass
  def validate_param_sources
    return if errors.any?

    properties = input_schema['properties'].is_a?(Hash) ? input_schema['properties'] : {}
    unknown = param_sources.keys - properties.keys
    return errors.add(:param_sources, I18n.t('captain.mcp_server.tools.unknown_param', tool: name, names: unknown.join(', '))) if unknown.any?

    validate_verified_email_param(properties)
  end

  def validate_verified_email_param(properties)
    verified = param_sources.select { |_name, source| source['source'] == PARAM_SOURCE_VERIFIED_EMAIL }.keys
    return errors.add(:param_sources, I18n.t('captain.mcp_server.tools.one_verified_email', tool: name)) if verified.size > 1
    # Verified values are text, so a parameter that takes one must be a string
    return if verified.none? || properties.dig(verified.first, 'type') == 'string'

    errors.add(:param_sources, I18n.t('captain.mcp_server.tools.verified_email_type', tool: name, name: verified.first))
  end
end
