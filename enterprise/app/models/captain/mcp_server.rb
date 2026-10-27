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

  belongs_to :account
  belongs_to :assistant, class_name: 'Captain::Assistant'

  enum :auth_type, %w[none oauth token].index_by(&:itself), prefix: :auth, validate: true
  enum :status, %w[active needs_sign_in error].index_by(&:itself), validate: true

  # oauth_credentials holds what RubyLLM stores for OAuth sign-in. The admin's token stays in auth_config.
  encrypts :auth_config, :oauth_credentials if Chatwoot.encryption_configured?

  alias_attribute :endpoint_url, :url

  validates :url, presence: true, uniqueness: { scope: :assistant_id }
  validates :name, presence: true
  validates_with Captain::McpServerToolsValidator
  validate :validate_auth_header
  validate :validate_token

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
end
