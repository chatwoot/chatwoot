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
  CITATION_SOURCES_STATE_KEY = :captain_v2_citation_sources
  AUTO_RESOLVE_MODES = %w[disabled legacy evaluated].freeze
  DEFAULT_INACTIVITY_THRESHOLD_MINUTES = 60
  MINIMUM_INACTIVITY_THRESHOLD_MINUTES = 5
  MAXIMUM_INACTIVITY_THRESHOLD_MINUTES = 1.day.in_minutes.to_i
  INACTIVITY_THRESHOLD_STEP_MINUTES = 5
  RESPONSE_WINDOWS = %w[always business_hours outside_business_hours].freeze

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
  has_many :conversation_outcomes, dependent: :destroy_async

  store_accessor :config, :temperature, :feature_faq, :feature_memory, :feature_contact_attributes, :product_name,
                 :auto_resolve_mode, :auto_resolve_after, :send_inactivity_resolution_message, :response_window

  before_validation :set_default_auto_resolve_mode, on: :create
  before_validation :normalize_auto_resolve_after

  validates :name, presence: true
  validates :description, presence: true, length: { maximum: DESCRIPTION_LENGTH_LIMIT }
  validates :account_id, presence: true
  validates_with Captain::AudienceValidator
  validate :validate_response_window
  validates :auto_resolve_mode, inclusion: { in: AUTO_RESOLVE_MODES }
  validates :send_inactivity_resolution_message, inclusion: { in: [true, false] }
  validates :auto_resolve_after,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: MINIMUM_INACTIVITY_THRESHOLD_MINUTES,
              less_than_or_equal_to: MAXIMUM_INACTIVITY_THRESHOLD_MINUTES
            },
            allow_nil: true

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

  def available_now?(conversation)
    response_window = config['response_window']
    return true if response_window.blank? || response_window == 'always'

    inbox = conversation.inbox
    return true unless inbox.working_hours_enabled?

    response_window == 'business_hours' ? !inbox.out_of_office? : inbox.out_of_office?
  end

  def auto_resolve_mode
    config.fetch('auto_resolve_mode') { account&.captain_auto_resolve_mode || 'evaluated' }
  end

  def inactive_conversation_resolution_disabled?
    auto_resolve_mode == 'disabled'
  end

  def evaluate_inactive_conversations_before_resolving?
    auto_resolve_mode == 'evaluated'
  end

  def inactivity_threshold_minutes
    return DEFAULT_INACTIVITY_THRESHOLD_MINUTES unless account.feature_enabled?('captain_integration_v2')

    (config['auto_resolve_after'] || DEFAULT_INACTIVITY_THRESHOLD_MINUTES).to_i
  end

  def send_inactivity_resolution_message
    return true unless account.feature_enabled?('captain_integration_v2')

    config.fetch('send_inactivity_resolution_message', true)
  end

  def send_inactivity_resolution_message?
    send_inactivity_resolution_message
  end

  def available_agent_tools
    tools = self.class.built_in_agent_tools.dup

    custom_tools = account.captain_custom_tools.enabled.map(&:to_tool_metadata)
    tools.concat(custom_tools)

    tools
  end

  def available_tool_ids = available_agent_tools.pluck(:id)

  def known_tool_ids
    self.class.built_in_tool_ids + account.captain_custom_tools.pluck(:slug)
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

  def customer_visible_citation_urls(citation_document_ids)
    citation_documents = documents.where(id: citation_document_ids.values).index_by(&:id)
    citation_urls = citation_document_ids.transform_values do |document_id|
      citation_documents[document_id.to_i]&.customer_visible_source_url
    end
    citation_urls.compact.transform_keys(&:to_i)
  end

  def citations_enabled?
    config['feature_citation']
  end

  def trusted_citation_urls(run_result)
    return {} unless citations_enabled?

    citation_document_ids = run_result&.context&.dig(:state, CITATION_SOURCES_STATE_KEY) || {}
    customer_visible_citation_urls(citation_document_ids)
  end

  private

  def normalize_auto_resolve_after
    threshold = Integer(auto_resolve_after.to_s, exception: false)
    return unless threshold&.between?(MINIMUM_INACTIVITY_THRESHOLD_MINUTES, MAXIMUM_INACTIVITY_THRESHOLD_MINUTES)

    # Keep API values aligned with the five minute options available in the settings UI.
    self.auto_resolve_after = (threshold.fdiv(INACTIVITY_THRESHOLD_STEP_MINUTES).round * INACTIVITY_THRESHOLD_STEP_MINUTES)
  end

  def validate_response_window
    response_window = config['response_window']
    return if response_window.blank?

    errors.add(:config, 'invalid response_window') unless RESPONSE_WINDOWS.include?(response_window)
  end

  def set_default_auto_resolve_mode
    return if config.key?('auto_resolve_mode')

    self.auto_resolve_mode = account&.captain_auto_resolve_mode || 'evaluated'
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
      citation_enabled: citations_enabled?,
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
