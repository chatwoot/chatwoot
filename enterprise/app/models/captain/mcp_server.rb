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
  enum :status, %w[active needs_sign_in error].index_by(&:itself), validate: true

  # oauth_credentials holds what RubyLLM stores for OAuth sign-in. The admin's token stays in auth_config.
  encrypts :auth_config, :oauth_credentials if Chatwoot.encryption_configured?

  # An OAuth server cannot be used until an admin signs in
  before_create { self.status = :needs_sign_in if auth_oauth? }
  # A new token clears the error the old token caused, the same way a new server starts as active
  before_update :reset_status, if: :will_save_change_to_auth_config?

  # SafeEndpointValidatable checks endpoint_url
  alias_attribute :endpoint_url, :url
  validates :url, presence: true, uniqueness: { scope: :assistant_id }
  validate :validate_plain_url
  validates :name, presence: true
  validate :validate_auth_header
  validate :validate_token

  scope :enabled, -> { where(enabled: true) }

  # Approved tools Captain may use. A caller must still compare each digest with the live definition.
  def available_tools
    enabled? ? tools.where(enabled: true) : Captain::McpTool.none
  end

  private

  def reset_status
    self.status = :active
    self.last_error = nil
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
