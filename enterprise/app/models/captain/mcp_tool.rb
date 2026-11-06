# == Schema Information
#
# Table name: captain_mcp_tools
#
#  id                  :bigint           not null, primary key
#  approved_definition :jsonb            not null
#  approved_digest     :string           not null
#  captain_name        :string           not null
#  enabled             :boolean          default(TRUE), not null
#  name                :string           not null
#  param_sources       :jsonb            not null
#  settings            :jsonb            not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :bigint           not null
#  mcp_server_id       :bigint           not null
#
# Indexes
#
#  index_captain_mcp_tools_on_account_id              (account_id)
#  index_captain_mcp_tools_on_captain_name            (captain_name) UNIQUE
#  index_captain_mcp_tools_on_mcp_server_id_and_name  (mcp_server_id,name) UNIQUE
#
# A tool on an MCP server that an admin approved for Captain, pinned to the definition the admin reviewed.
# Captain uses it only while the server's live definition still matches approved_digest.
class Captain::McpTool < ApplicationRecord
  self.table_name = 'captain_mcp_tools'

  # OpenAI function names allow these characters only, and at most 64 of them
  INVALID_NAME_CHARACTERS = /[^a-zA-Z0-9_-]/
  MAX_CAPTAIN_NAME_LENGTH = Captain::CustomTool::MAX_SLUG_LENGTH

  belongs_to :account
  belongs_to :mcp_server, class_name: 'Captain::McpServer'

  # Set once, so scenarios that reference the tool keep working if the naming rule changes later
  before_validation :assign_captain_name, on: :create

  validates :name, presence: true, uniqueness: { scope: :mcp_server_id }
  validates :approved_digest, format: { with: /\Asha256:[0-9a-f]{64}\z/ }
  validates_with JsonSchemaValidator,
                 schema: Captain::CustomTool::SETTINGS_VALIDATION,
                 attribute_resolver: ->(record) { record.settings }
  validates :enabled, inclusion: { in: [true, false] }
  # The name is set once on create, so only a new tool can clash
  validate :validate_captain_name, on: :create
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

  def read_only?
    approved_definition['read_only']
  end

  # The tool runs only for a customer who proved who they are, so Captain offers email verification.
  # The admin can turn this on with a setting. A parameter that takes a proven value cannot be filled
  # without that proof, so it needs no setting.
  def requires_verified_customer?
    settings['requires_email_verification'] == true || param_sources.values.any? { |entry| Captain::ParamSources.proven?(entry) }
  end

  private

  # The name Captain sees. The server ID keeps names apart across servers, and the double underscore
  # keeps server 1's tool "2_x" apart from server 12's tool "x".
  def assign_captain_name
    self.captain_name ||= "#{Captain::McpServer::TOOL_NAME_PREFIX}_#{mcp_server_id}__#{name.to_s.gsub(INVALID_NAME_CHARACTERS, '_')}"
                          .first(MAX_CAPTAIN_NAME_LENGTH)
  end

  # Captain names replace unsupported characters and cut long names, so two server names can become one.
  # The unique index keeps that true under concurrent saves; this check gives the admin a readable error.
  def validate_captain_name
    clash = self.class.where(captain_name: captain_name).where.not(id: id).first
    errors.add(:name, I18n.t('captain.mcp_server.tools.name_clash', names: [clash.name, name].join(', '))) if clash
  end

  def validate_param_sources
    properties = input_schema['properties'].is_a?(Hash) ? input_schema['properties'] : {}
    Captain::ParamSources.validate(param_sources, properties: properties, tool_name: name)
                         .each { |error| errors.add(:param_sources, error) }
  end
end
