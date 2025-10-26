class Enterprise::Billing::V2::CancelSubscriptionService < Enterprise::Billing::V2::BaseService
  include Enterprise::Billing::Concerns::PlanFeatureManager

  # Cancel subscription at period end using Stripe's V1 API
  # Subscription remains active until the end of the current billing period
  # Customer receives no refund/credit for remaining time
  #
  # @return [Hash] { success:, cancel_at_period_end:, period_end:, message: }
  #
  def cancel_subscription
    return { success: false, message: 'Not a V2 billing account' } unless v2_enabled?
    return { success: false, message: 'No active subscription' } unless active_subscription?

    with_locked_account do
      subscription_data = cancel_at_period_end
      update_account_status(subscription_data)
      success_response = build_success_response(subscription_data)
      success_response
    end
  rescue Stripe::StripeError => e
    { success: false, message: "Stripe error: #{e.message}" }
  rescue StandardError => e
    { success: false, message: "Cancellation error: #{e.message}" }
  end

  private

  def cancel_at_period_end
    subscription_id = custom_attribute('stripe_subscription_id')
    raise StandardError, 'No subscription ID found' if subscription_id.blank?

    # Build update parameters to cancel at period end
    params = {
      cancel_at_period_end: true
    }

    StripeV2Client.request(
      :post,
      "/v1/subscriptions/#{subscription_id}",
      params,
      stripe_api_options
    )
  end

  def update_account_status(subscription_data)
    # Extract period end from subscription data
    current_period_end = extract_attribute(subscription_data, :current_period_end)
    period_end_time = current_period_end ? Time.zone.at(current_period_end).iso8601 : nil

    # Mark subscription as cancelling (will be cancelled at period end)
    update_custom_attributes({
                               'subscription_status' => 'cancel_at_period_end',
                               'subscription_cancelled_at' => Time.current.iso8601,
                               'subscription_period_end' => period_end_time
                             })
  end

  def build_success_response(subscription_data)
    current_period_end = extract_attribute(subscription_data, :current_period_end)
    period_end_time = current_period_end ? Time.zone.at(current_period_end) : nil

    {
      success: true,
      cancel_at_period_end: true,
      period_end: period_end_time,
      message: 'Subscription will be cancelled at the end of the current billing period.'
    }
  end

  def v2_enabled?
    custom_attribute('stripe_billing_version')&.to_i == 2
  end

  def active_subscription?
    custom_attribute('subscription_status') == 'active'
  end

  def stripe_api_options
    { api_key: ENV.fetch('STRIPE_SECRET_KEY', nil), stripe_version: '2025-08-27.preview' }
  end

  def extract_attribute(object, key)
    object.respond_to?(key) ? object.public_send(key) : object[key.to_s]
  end
end
