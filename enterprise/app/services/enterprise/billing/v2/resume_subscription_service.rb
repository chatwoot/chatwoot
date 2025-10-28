class Enterprise::Billing::V2::ResumeSubscriptionService < Enterprise::Billing::V2::BaseService
  include Enterprise::Billing::Concerns::PlanFeatureManager

  # Resume a cancelled subscription by creating an activate billing intent
  # This reactivates the subscription to continue beyond the current period
  #
  # @return [Hash] { success:, message: }
  #
  def resume_subscription
    return { success: false, message: 'Not a V2 billing account' } unless v2_enabled?
    return { success: false, message: 'Subscription is not pending cancellation' } unless cancelling_subscription?

    with_locked_account do
      billing_intent = create_activate_intent
      reserve_billing_intent(billing_intent)
      commit_billing_intent(billing_intent)
      update_account_status(billing_intent)
      success_response = build_success_response(billing_intent)
      success_response
    end
  rescue Stripe::StripeError => e
    { success: false, message: "Stripe error: #{e.message}" }
  rescue StandardError => e
    { success: false, message: "Resume error: #{e.message}" }
  end

  private

  def create_activate_intent
    subscription_id = fetch_subscription_id
    plan_id = fetch_plan_id
    cadence_id = fetch_cadence_from_subscription(subscription_id)
    plan_version = fetch_plan_version(plan_id)

    StripeV2Client.request(
      :post,
      '/v2/billing/intents',
      build_activate_params(cadence_id, plan_id, plan_version),
      stripe_api_options
    )
  end

  def fetch_subscription_id
    custom_attribute('stripe_subscription_id').tap do |id|
      raise StandardError, 'No pricing plan subscription ID found' if id.blank?
    end
  end

  def fetch_plan_id
    custom_attribute('stripe_pricing_plan_id')
  end

  def fetch_cadence_from_subscription(subscription_id)
    subscription = retrieve_pricing_plan_subscription(subscription_id)
    extract_attribute(subscription, :billing_cadence).tap do |cadence_id|
      raise StandardError, 'No billing cadence found in subscription' if cadence_id.blank?
    end
  end

  def fetch_plan_version(plan_id)
    plan = retrieve_pricing_plan(plan_id)
    extract_attribute(plan, :latest_version)
  end

  def build_activate_params(cadence_id, plan_id, plan_version)
    {
      cadence: cadence_id,
      currency: 'usd',
      actions: [{
        type: 'subscribe',
        subscribe: {
          type: 'pricing_plan_subscription_details',
          pricing_plan_subscription_details: {
            pricing_plan: plan_id,
            pricing_plan_version: plan_version
          }
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

  def retrieve_pricing_plan(pricing_plan_id)
    StripeV2Client.request(
      :get,
      "/v2/billing/pricing_plans/#{pricing_plan_id}",
      {},
      stripe_api_options
    )
  end

  def update_account_status(_billing_intent)
    # Mark subscription as active again (remove cancel_at_period_end flag and end date)
    update_custom_attributes({
                               'subscription_status' => 'active',
                               'subscription_cancelled_at' => nil,
                               'subscription_ends_at' => nil
                             })
  end

  def build_success_response(_billing_intent)
    {
      success: true,
      message: 'Subscription resumed successfully. It will now continue beyond the current billing period.'
    }
  end

  def v2_enabled?
    custom_attribute('stripe_billing_version')&.to_i == 2
  end

  def cancelling_subscription?
    custom_attribute('subscription_status') == 'cancel_at_period_end'
  end

  def stripe_api_options
    { api_key: ENV.fetch('STRIPE_SECRET_KEY', nil), stripe_version: '2025-08-27.preview' }
  end

  def extract_attribute(object, key)
    object.respond_to?(key) ? object.public_send(key) : object[key.to_s]
  end
end
