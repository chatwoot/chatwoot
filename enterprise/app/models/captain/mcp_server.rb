# == Schema Information
#
# Table name: captain_mcp_servers
#
#  id                :bigint           not null, primary key
#  auth_config       :jsonb
#  auth_header       :string
#  auth_type         :string           default("none"), not null
#  enabled           :boolean          default(TRUE), not null
#  last_error        :text
#  name              :string           not null
#  oauth_credentials :jsonb
#  status            :string           default("active"), not null
#  tools_changed_at  :datetime
#  url               :text             not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#  assistant_id      :bigint           not null
#
# Indexes
#
#  index_captain_mcp_servers_on_account_id            (account_id)
#  index_captain_mcp_servers_on_assistant_id_and_url  (assistant_id,url) UNIQUE
#
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

  belongs_to :account
  belongs_to :assistant, class_name: 'Captain::Assistant'
  has_many :tools, -> { order(:id) }, class_name: 'Captain::McpTool', inverse_of: :mcp_server, dependent: :delete_all

  enum :auth_type, %w[none oauth token].index_by(&:itself), prefix: :auth, validate: true
  enum :status, %w[active needs_sign_in error].index_by(&:itself), validate: true

  # oauth_credentials holds what RubyLLM stores for OAuth sign-in. The admin's token stays in auth_config.
  encrypts :auth_config, :oauth_credentials if Chatwoot.encryption_configured?

  alias_attribute :endpoint_url, :url

  validates :url, presence: true, uniqueness: { scope: :assistant_id }
  validates :name, presence: true
  validate :validate_auth_header
  validate :validate_token

  scope :enabled, -> { where(enabled: true) }

  # The servers Captain may use for an assistant: none while the account does not have MCP servers turned on
  def self.usable_for(assistant)
    assistant.account.feature_enabled?(FEATURE_FLAG) ? assistant.mcp_servers.enabled : none
  end

  # The name Captain sees. The server ID keeps names apart across servers, and the double underscore
  # keeps server 1's tool "2_x" apart from server 12's tool "x".
  def captain_tool_name(server_tool_name)
    "#{TOOL_NAME_PREFIX}_#{id}__#{server_tool_name.gsub(INVALID_TOOL_NAME_CHARACTERS, '_')}".first(MAX_TOOL_NAME_LENGTH)
  end

  # Approved tools Captain may use. The runtime still checks each digest against the live definition.
  def available_tools
    enabled? ? tools.where(enabled: true) : Captain::McpTool.none
  end

  # Scenarios list and reference these tools by their Captain name
  def tool_metadata
    available_tools.map { |tool| { id: tool.captain_name, title: tool.name, description: tool.description, mcp: true } }
  end

  def requires_email_verification?
    available_tools.any?(&:requires_email_verification?)
  end

  # Approved tools whose live definition differs from the approved one, or that the server no longer lists
  def changed_tool_names(live_definitions)
    live = live_definitions.index_by { |definition| definition['name'] }
    tools.reject { |tool| live[tool.name] && tool.approval_current?(live[tool.name]) }.map(&:name)
  end

  # Records when a change first appeared, and clears it once no approved tool differs
  def record_tool_changes(live_definitions)
    changed = changed_tool_names(live_definitions).any?
    return if changed == tools_changed_at.present?

    update_columns(tools_changed_at: changed ? Time.current : nil) # rubocop:disable Rails/SkipsModelValidations
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
