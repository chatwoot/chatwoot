module Enterprise::Concerns::Account
  extend ActiveSupport::Concern

  included do
    store_accessor :settings, :conversation_required_attributes

    has_many :sla_policies, dependent: :destroy_async
    has_many :applied_slas, dependent: :destroy_async
    has_many :custom_roles, dependent: :destroy_async
    has_many :agent_capacity_policies, dependent: :destroy_async

    has_many :captain_assistants, dependent: :destroy_async, class_name: 'Captain::Assistant'
    has_many :captain_assistant_responses, dependent: :destroy_async, class_name: 'Captain::AssistantResponse'
    has_many :captain_faq_observations, dependent: :destroy_async, class_name: 'Captain::FaqObservation'
    has_many :captain_faq_suggestions, dependent: :destroy_async, class_name: 'Captain::FaqSuggestion'
    has_many :captain_documents, dependent: :destroy_async, class_name: 'Captain::Document'
    has_many :captain_custom_tools, dependent: :destroy_async, class_name: 'Captain::CustomTool'
    has_many :captain_agent_sessions, dependent: :destroy_async, class_name: 'Captain::AgentSession'
    has_many :conversation_outcomes, dependent: :destroy_async
    has_many :conversation_monitors, class_name: 'ConversationMonitors::Monitor', dependent: :destroy_async
    has_many :monitor_automation_deliveries, class_name: 'ConversationMonitors::AutomationDelivery', dependent: :delete_all

    has_many :copilot_threads, dependent: :destroy_async
    has_many :calls, dependent: :destroy_async

    has_one :saml_settings, dependent: :destroy_async, class_name: 'AccountSamlSettings'

    after_create_commit :start_cloud_trial
  end

  private

  # Every Stripe-billed cloud account starts its trial when it's created. Accounts created without an administrator
  # (Super Admin, Platform API) have no one to bill yet, so they get the free plan from the billing page instead.
  def start_cloud_trial
    return unless Enterprise::Billing::TrialService.enabled? && billing_provider == Account::DEFAULT_BILLING_PROVIDER
    return unless administrators.exists?

    update!(custom_attributes: custom_attributes.merge('is_creating_customer' => true))
    Enterprise::CreateStripeCustomerJob.perform_later(self, trial_end: Enterprise::Billing::TrialService::TRIAL_DAYS.days.from_now.to_i)
  end
end
