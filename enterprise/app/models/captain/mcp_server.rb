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

  alias_attribute :endpoint_url, :url

  validates :url, presence: true, uniqueness: { scope: :assistant_id }
  validates :name, presence: true
  validate :validate_plain_url
  validate :validate_auth_header
  validate :validate_token

  # An OAuth server cannot be used until an admin signs in
  before_create { self.status = :needs_sign_in if auth_oauth? }
  # A new token clears the error the old token caused, the same way a new server starts as active
  before_update :reset_status, if: :will_save_change_to_auth_config?

  scope :enabled, -> { where(enabled: true) }

  # The name Captain sees. The server ID keeps names apart across servers, and the double underscore
  # keeps server 1's tool "2_x" apart from server 12's tool "x".
  def captain_tool_name(server_tool_name)
    "#{TOOL_NAME_PREFIX}_#{id}__#{server_tool_name.gsub(INVALID_TOOL_NAME_CHARACTERS, '_')}".first(MAX_TOOL_NAME_LENGTH)
  end

  # Approved tools Captain may use. The runtime still checks each digest against the live definition.
  def available_tools
    enabled? ? tools.where(enabled: true) : Captain::McpTool.none
  end

  # Selected tool names that have no approved tool yet. Only these need the server's live definitions.
  def new_tool_names(names)
    names - tools.pluck(:name)
  end

  # Makes the approved tools match the selections, a hash of fields by tool name. A tool that is already approved keeps
  # its approved definition, so editing its parameters never approves a change the server made, and fields the
  # selection leaves out keep their values. A newly selected tool is pinned to its definition in live_definitions,
  # which must be read-only.
  def sync_tools(selections, live_definitions)
    transaction do
      approved = tools.index_by(&:name)
      tools.where.not(name: selections.keys).delete_all
      selections.each do |name, fields|
        tool = approved[name] || approved_tool(name, live_definitions[name])
        tool.update!(fields)
      end
    end
    # The loaded list still holds the deleted tools
    tools.reset
  end

  # Adds the error to the server and raises, so the API answers 422 with the reason
  def invalid_tool!(name, reason)
    errors.add(:tools, I18n.t("captain.mcp_server.tools.#{reason}", tool: name))
    raise ActiveRecord::RecordInvalid, self
  end

  private

  def reset_status
    self.status = :active
    self.last_error = nil
  end

  def approved_tool(name, definition)
    invalid_tool!(name, :missing) unless definition
    invalid_tool!(name, :not_read_only) unless definition['read_only']

    tools.new(account: account, name: name).tap { |tool| tool.approve(definition) }
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
