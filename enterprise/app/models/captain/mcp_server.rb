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
# Captain uses only approved tools, and only while the live definition still matches the approved digest.
class Captain::McpServer < ApplicationRecord
  include Concerns::SafeEndpointValidatable
  include Concerns::McpToolApprovable

  self.table_name = 'captain_mcp_servers'

  FEATURE_FLAG = 'captain_mcp_servers'.freeze
  # Matches how long RubyLLM keeps a pending OAuth sign-in
  OAUTH_STATE_TTL = 10.minutes

  # Starts the name of the RubyLLM client and of every tool Captain sees from a server
  TOOL_NAME_PREFIX = 'mcp'.freeze

  # RubyLLM sets these on MCP requests after the token header, so a token header with one of these names would replace
  # them. Authorization is free: a server with its own token header gets no bearer token.
  RESERVED_HEADERS = %w[host content-length content-type accept last-event-id].freeze
  RESERVED_HEADER_PREFIX = 'mcp-'.freeze

  belongs_to :account
  belongs_to :assistant, class_name: 'Captain::Assistant'
  has_many :tools, -> { order(:id) }, class_name: 'Captain::McpTool', inverse_of: :mcp_server, dependent: :delete_all

  enum :auth_type, %w[none oauth token].index_by(&:itself), prefix: :auth, validate: true
  # Whether the saved credentials work. After create, only credentials_rejected! and credentials_accepted! change it.
  enum :status, %w[active needs_credentials].index_by(&:itself), validate: true

  # oauth_credentials holds what RubyLLM stores for OAuth sign-in. The admin's token stays in auth_config.
  encrypts :auth_config, :oauth_credentials if Chatwoot.encryption_configured?

  # An OAuth server has no credentials until an admin signs in
  before_create { self.status = :needs_credentials if auth_oauth? }
  # A token server's credentials are its token, so a new token replaces the rejected one
  before_update :accept_new_token, if: -> { auth_token? && will_save_change_to_auth_config? }

  # SafeEndpointValidatable checks endpoint_url
  alias_attribute :endpoint_url, :url
  validates :url, presence: true, uniqueness: { scope: :assistant_id }
  validate :validate_plain_url
  validates :name, presence: true
  validates :enabled, inclusion: { in: [true, false] }
  validate :validate_auth_header
  validate :validate_token

  scope :enabled, -> { where(enabled: true) }

  # The servers Captain may use for an assistant: none while the account does not have MCP servers turned on
  def self.usable_for(assistant)
    assistant.account.feature_enabled?(FEATURE_FLAG) ? assistant.mcp_servers.enabled : none
  end

  # Returns the server an OAuth sign-in with this state started for, once. Every server shares one callback URL, so the
  # state is the only way to find the server, and a used state is deleted so a repeated callback finds nothing.
  def self.for_oauth_state(state)
    key = format(::Redis::RedisKeys::CAPTAIN_MCP_OAUTH_STATE, state: state.to_s)
    server_id = ::Redis::Alfred.get(key)
    ::Redis::Alfred.delete(key)
    find_by(id: server_id) if server_id
  end

  # Remembers which server an OAuth sign-in started for, so the callback can find it
  def remember_oauth_state(state)
    ::Redis::Alfred.setex(format(::Redis::RedisKeys::CAPTAIN_MCP_OAUTH_STATE, state: state), id, OAUTH_STATE_TTL)
  end

  # Approved tools Captain may use. A caller must still compare each digest with the live definition.
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

  # The two status changes after create write only when the value changes, with update_columns and not save:
  # - ServerUpdateService sends a request after it assigns the admin's edit and before it saves it. A save here would
  #   store that edit before the service saves the tool selection in the same transaction.
  # - A validation on an unrelated column must not stop Chatwoot from recording what the server said.

  # The server rejected the saved credentials, so an admin must sign in again or enter a new token
  def credentials_rejected!
    update_columns(status: :needs_credentials) unless needs_credentials? # rubocop:disable Rails/SkipsModelValidations
  end

  # The saved credentials worked, so an earlier request failure no longer applies
  def credentials_accepted!
    return if active? && last_error.nil?

    update_columns(status: :active, last_error: nil) # rubocop:disable Rails/SkipsModelValidations
  end

  # A request failed for a reason other than the credentials. It says nothing about the status.
  def record_request_error(message)
    update_columns(last_error: message) unless last_error == message # rubocop:disable Rails/SkipsModelValidations
  end

  private

  def accept_new_token
    self.status = :active
  end

  # The shared endpoint check accepts Liquid templates for custom tools, but RubyLLM connects to the URL as written.
  # It refuses a URL with a username or password, so neither may reach it.
  def validate_plain_url
    return if url.blank?

    errors.add(:endpoint_url, 'cannot contain a username or password') if URI.parse(url).userinfo
  rescue URI::InvalidURIError
    errors.add(:endpoint_url, 'must be a valid URL')
  end

  def validate_auth_header
    return if auth_header.nil?
    return errors.add(:auth_header, :invalid) unless Captain::CustomTool::HEADER_NAME_PATTERN.match?(auth_header)

    name = auth_header.downcase
    return unless RESERVED_HEADERS.include?(name) || name.start_with?(RESERVED_HEADER_PREFIX)

    errors.add(:auth_header, I18n.t('captain.mcp_server.reserved_header', name: auth_header))
  end

  # The token is sent as a header value, so control characters would break the request
  def validate_token
    errors.add(:auth_config, :invalid) if auth_config['token'].to_s.match?(/[[:cntrl:]]/)
  end
end
