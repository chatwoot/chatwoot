class Enterprise::Billing::V2::CancelSubscriptionService < Enterprise::Billing::V2::BaseService
  include Enterprise::Billing::Concerns::PlanFeatureManager

  # Cancel subscription using Stripe's V2 Billing Intent API
  # Creates a deactivate billing intent for the pricing plan subscription
  # Subscription remains active until the end of the current billing period
  #
  # @return [Hash] { success:, cancel_at_period_end:, period_end:, message: }
  #
  def cancel_subscription
    with_locked_account do
      billing_intent = create_deactivate_intent
      reserve_billing_intent(billing_intent)
      commit_billing_intent(billing_intent)
      update_account_status(billing_intent)
      success_response = build_success_response(billing_intent)
      success_response
    end
  rescue Stripe::StripeError => e
    { success: false, message: "Stripe error: #{e.message}" }
  rescue StandardError => e
    { success: false, message: "Cancellation error: #{e.message}" }
  end

  private

  def create_deactivate_intent
    pricing_plan_subscription_id = fetch_subscription_id
    billing_cadence_id = fetch_billing_cadence_id(pricing_plan_subscription_id)
    store_next_billing_date(billing_cadence_id)

    StripeV2Client.request(
      :post,
      '/v2/billing/intents',
      build_deactivate_params(pricing_plan_subscription_id, billing_cadence_id),
      stripe_api_options
    )
  end

  def fetch_subscription_id
    custom_attribute('stripe_subscription_id').tap do |id|
      raise StandardError, 'No pricing plan subscription ID found' if id.blank?
    end
  end

  def fetch_billing_cadence_id(subscription_id)
    subscription = retrieve_pricing_plan_subscription(subscription_id)
    extract_attribute(subscription, :billing_cadence).tap do |cadence_id|
      raise StandardError, 'No billing cadence found in subscription' if cadence_id.blank?
    end
  end

  def store_next_billing_date(cadence_id)
    cadence = retrieve_billing_cadence(cadence_id)
    Rails.logger.info("Cadence: #{cadence}")
    @next_billing_date = extract_attribute(cadence, :next_billing_date)
  end

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

  def reserve_billing_intent(billing_intent)
    StripeV2Client.request(
      :post,
      "/v2/billing/intents/#{billing_intent.id}/reserve",
      {},
      stripe_api_options
    )
  end

  def commit_billing_intent(billing_intent)
    StripeV2Client.request(
      :post,
      "/v2/billing/intents/#{billing_intent.id}/commit",
      {},
      stripe_api_options
    )
  end

  def retrieve_pricing_plan_subscription(subscription_id)
    StripeV2Client.request(
      :get,
      "/v2/billing/pricing_plan_subscriptions/#{subscription_id}",
      {},
      stripe_api_options
    )
  end

  def retrieve_billing_cadence(cadence_id)
    StripeV2Client.request(
      :get,
      "/v2/billing/cadences/#{cadence_id}",
      {},
      stripe_api_options
    )
  end

  def update_account_status(_billing_intent)
    # Mark subscription as cancelling (will be cancelled at period end)
    # Store next_billing_date so the UI can show when the subscription ends
    update_custom_attributes({
                               'subscription_status' => 'cancel_at_period_end',
                               'subscription_cancelled_at' => Time.current.iso8601,
                               'subscription_ends_at' => @next_billing_date
                             })
  end

  def build_success_response(_billing_intent)
    {
      success: true,
      cancel_at_period_end: true,
      message: 'Subscription cancellation initiated. It will be deactivated at the end of the current billing period.'
    }
  end

  def stripe_api_options
    { api_key: ENV.fetch('STRIPE_SECRET_KEY', nil), stripe_version: '2025-08-27.preview' }
  end

  def extract_attribute(object, key)
    object.respond_to?(key) ? object.public_send(key) : object[key.to_s]
  end
end
