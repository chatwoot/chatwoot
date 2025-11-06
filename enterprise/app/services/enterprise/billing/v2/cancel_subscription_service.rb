class Enterprise::Billing::V2::CancelSubscriptionService < Enterprise::Billing::V2::BaseService
  include Enterprise::Billing::Concerns::PlanFeatureManager
  include Enterprise::Billing::Concerns::StripeV2ClientHelper
  include Enterprise::Billing::Concerns::BillingIntentWorkflow
  include Enterprise::Billing::Concerns::SubscriptionDataManager

  # Cancel subscription using Stripe's V2 Billing Intent API
  # Creates a deactivate billing intent for the pricing plan subscription
  # Subscription remains active until the end of the current billing period
  #
  # @return [Hash] { success:, cancel_at_period_end:, period_end:, message: }
  #
  def cancel_subscription
    with_locked_account do
      metadata = fetch_subscription_metadata
      intent_params = build_deactivate_params(metadata[:subscription_id], metadata[:cadence_id])
      execute_billing_intent(intent_params)
      update_account_status(metadata[:next_billing_date])
      build_success_response
    end
  rescue Stripe::StripeError => e
    { success: false, message: "Stripe error: #{e.message}" }
  rescue StandardError => e
    { success: false, message: "Cancellation error: #{e.message}" }
  end

  private

  def build_deactivate_params(subscription_id, cadence_id)
    {
      cadence: cadence_id,
      currency: 'usd',
      actions: [{
        type: 'deactivate',
        deactivate: {
          type: 'pricing_plan_subscription_details',
          pricing_plan_subscription_details: { pricing_plan_subscription: subscription_id }
        }
      }]
    }
  end

  def update_account_status(next_billing_date)
    # Mark subscription as cancelling (will be cancelled at period end)
    # Store next_billing_date so the UI can show when the subscription ends
    update_custom_attributes({
                               'subscription_status' => 'cancel_at_period_end',
                               'subscription_cancelled_at' => Time.current.iso8601,
                               'subscription_ends_at' => next_billing_date
                             })
  end

  def build_success_response
    {
      success: true,
      cancel_at_period_end: true,
      message: 'Subscription cancellation initiated. It will be deactivated at the end of the current billing period.'
    }
  end
end
