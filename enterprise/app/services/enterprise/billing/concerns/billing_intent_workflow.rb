module Enterprise::Billing::Concerns::BillingIntentWorkflow
  extend ActiveSupport::Concern

  private

  # Execute a billing intent with automatic reserve and commit
  def execute_billing_intent(intent_params)
    intent = create_billing_intent(intent_params)
    reserve_billing_intent(intent)
    yield(intent) if block_given?
    commit_billing_intent(intent)
    intent
  end
end
