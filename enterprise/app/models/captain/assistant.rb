# == Schema Information
#
# Table name: captain_assistants
#
#  id                  :bigint           not null, primary key
#  config              :jsonb            not null
#  description         :text
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
  DESCRIPTION_LENGTH_LIMIT = 500
  LANGUAGE_ELIGIBILITY_PENDING_KEY = 'captain_language_eligibility_pending'.freeze

  include Avatarable
  include Concerns::CaptainToolsHelpers
  include Concerns::Agentable

  self.table_name = 'captain_assistants'

  belongs_to :account
  has_many :documents, class_name: 'Captain::Document', dependent: :destroy_async
  has_many :responses, class_name: 'Captain::AssistantResponse', dependent: :destroy_async
  has_many :faq_suggestions, class_name: 'Captain::FaqSuggestion', dependent: :destroy_async
  has_many :captain_inboxes,
           class_name: 'CaptainInbox',
           foreign_key: :captain_assistant_id,
           dependent: :destroy_async
  has_many :inboxes,
           through: :captain_inboxes
  has_many :messages, as: :sender, dependent: :nullify
  has_many :copilot_threads, dependent: :destroy_async
  has_many :scenarios, class_name: 'Captain::Scenario', dependent: :destroy_async
  has_many :agent_sessions, class_name: 'Captain::AgentSession', dependent: :destroy_async

  store_accessor :config, :temperature, :feature_faq, :feature_memory, :feature_contact_attributes, :product_name, :response_window

  RESPONSE_WINDOWS = %w[always business_hours outside_business_hours].freeze

  validates :name, presence: true
  validates :description, presence: true, length: { maximum: DESCRIPTION_LENGTH_LIMIT }
  validates :account_id, presence: true
  validates_with Captain::AudienceValidator
  validate :validate_response_window

  scope :ordered, -> { order(created_at: :desc) }

  scope :for_account, ->(account_id) { where(account_id: account_id) }

  def available_name
    name
  end

  def engages?(contact, conversation)
    responds_to_audience?(contact, conversation) && available_now?(conversation)
  end

  def responds_to_audience?(contact, conversation)
    return true if config['audience'].blank?

    Captain::AudienceMatcher.new(config['audience']).matches?(contact, conversation)
  end

  def uses_conversation_language?
    Captain::AudienceMatcher.new(config['audience']).uses_attribute?('conversation_language')
  end

  def awaiting_conversation_language?(conversation)
    return false unless uses_conversation_language?
    return false if conversation.additional_attributes['conversation_language'].present?
    return false if responds_to_audience?(conversation.contact, conversation)

    account.hooks.enabled.exists?(app_id: 'google_translate')
  end

  def available_now?(conversation)
    response_window = config['response_window']
    return true if response_window.blank? || response_window == 'always'

    inbox = conversation.inbox
    return true unless inbox.working_hours_enabled?

    response_window == 'business_hours' ? !inbox.out_of_office? : inbox.out_of_office?
  end

  def available_agent_tools
    tools = self.class.built_in_agent_tools.dup

    custom_tools = account.captain_custom_tools.enabled.map(&:to_tool_metadata)
    tools.concat(custom_tools)

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

  def validate_response_window
    response_window = config['response_window']
    return if response_window.blank?

    errors.add(:config, 'invalid response_window') unless RESPONSE_WINDOWS.include?(response_window)
  end

  def agent_name
    name.parameterize(separator: '_')
  end

  def agent_tools
    [
      self.class.resolve_tool_class('faq_lookup').new(self),
      self.class.resolve_tool_class('handoff').new(self),
      *account.captain_custom_tools.enabled.map { |custom_tool| custom_tool.tool(self) }
    ]
  end

  def prompt_context
    {
      name: name,
      description: description,
      product_name: config['product_name'] || 'this product',
      scenarios: scenarios.enabled.map do |scenario|
        {
          title: scenario.title,
          key: scenario.handoff_key,
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
