# == Schema Information
#
# Table name: captain_assistants
#
#  id                  :bigint           not null, primary key
#  config              :jsonb            not null
#  description         :string
#  guardrails          :jsonb
#  name                :string           not null
#  response_guidelines :jsonb
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :bigint           not null
#
# Indexes
#
#  index_captain_assistants_on_account_id  (account_id)
#
class Captain::Assistant < ApplicationRecord
  include Avatarable
  include Concerns::CaptainToolsHelpers
  include Concerns::Agentable

  self.table_name = 'captain_assistants'

  belongs_to :account
  has_many :documents, class_name: 'Captain::Document', dependent: :destroy_async
  has_many :responses, class_name: 'Captain::AssistantResponse', dependent: :destroy_async
  has_many :captain_inboxes,
           class_name: 'CaptainInbox',
           foreign_key: :captain_assistant_id,
           dependent: :destroy_async
  has_many :inboxes,
           through: :captain_inboxes
  has_many :messages, as: :sender, dependent: :nullify
  has_many :copilot_threads, dependent: :destroy_async
  has_many :scenarios, class_name: 'Captain::Scenario', dependent: :destroy_async
  has_many :assistant_mcp_servers,
           class_name: 'Captain::AssistantMcpServer',
           foreign_key: :captain_assistant_id,
           inverse_of: :assistant,
           dependent: :destroy
  has_many :mcp_servers,
           through: :assistant_mcp_servers

  store_accessor :config, :temperature, :feature_faq, :feature_memory, :product_name

  validates :name, presence: true
  validates :description, presence: true
  validates :account_id, presence: true

  scope :ordered, -> { order(created_at: :desc) }

  scope :for_account, ->(account_id) { where(account_id: account_id) }

  def available_name
    name
  end

  def available_agent_tools
    tools = self.class.built_in_agent_tools.dup

    custom_tools = account.captain_custom_tools.enabled.map(&:to_tool_metadata)
    tools.concat(custom_tools)

    mcp_tools = assistant_mcp_servers.enabled
                                     .joins(:mcp_server)
                                     .merge(Captain::McpServer.enabled)
                                     .flat_map(&:to_tool_metadata)
    tools.concat(mcp_tools)

    tools
  end

  def available_tool_ids
    available_agent_tools.pluck(:id)
  end

  def push_event_data
    {
      id: id,
      name: name,
      avatar_url: avatar_url.presence || default_avatar_url,
      description: description,
      created_at: created_at,
      type: 'captain_assistant'
    }
  end

  def webhook_data
    {
      id: id,
      name: name,
      avatar_url: avatar_url.presence || default_avatar_url,
      description: description,
      created_at: created_at,
      type: 'captain_assistant'
    }
  end

  private

  def agent_name
    name.parameterize(separator: '_')
  end

  def agent_tools
    tools = [
      self.class.resolve_tool_class('faq_lookup').new(self),
      self.class.resolve_tool_class('handoff').new(self)
    ]

    # Add custom tools
    account.captain_custom_tools.enabled.each do |custom_tool|
      tools << custom_tool.tool(self)
    end

    # Add MCP tools from attached, enabled, connected servers
    assistant_mcp_servers.enabled
                         .joins(:mcp_server)
                         .merge(Captain::McpServer.enabled.connected)
                         .each do |ams|
      ams.filtered_tools.each do |tool_def|
        tool_instance = ams.mcp_server.build_tool_instance(self, tool_def['name'])
        tools << tool_instance if tool_instance
      end
    end

    tools
  end

  def prompt_context
    {
      name: name,
      description: description,
      product_name: config['product_name'] || 'this product',
      scenarios: scenarios.enabled.map do |scenario|
        {
          title: scenario.title,
          key: scenario.title.parameterize.underscore,
          description: scenario.description
        }
      end,
      response_guidelines: response_guidelines || [],
      guardrails: guardrails || []
    }
  end

  def default_avatar_url
    "#{ENV.fetch('FRONTEND_URL', nil)}/assets/images/dashboard/captain/logo.svg"
  end
end
