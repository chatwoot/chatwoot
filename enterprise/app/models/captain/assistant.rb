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

  store_accessor :config, :temperature, :feature_faq, :feature_memory, :product_name

  validates :name, presence: true
  validates :description, presence: true
  validates :account_id, presence: true

  scope :ordered, -> { order(created_at: :desc) }

  scope :for_account, ->(account_id) { where(account_id: account_id) }

  def available_name
    name
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
    name
  end

  def agent_tools
    [
      self.class.resolve_tool_class('faq_lookup').new(self),
      self.class.resolve_tool_class('handoff').new(self)
    ]
  end

  def prompt_context
    {
      name: name,
      description: description,
      product_name: config['product_name'] || 'this product',
      scenarios: scenarios.enabled.map do |scenario|
        {
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
