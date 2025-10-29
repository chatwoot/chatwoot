class Enterprise::Billing::V2::WebhookHandlerService
  def perform(event:)
    @event = event
    return { success: false, message: 'Event is required' } if @event.blank?

    return { success: false, message: 'Account not found' } if account.blank?

    case @event.type
    when 'v2.billing.pricing_plan_subscription.servicing_activated'
      Rails.logger.info "Handling subscription servicing activated event: #{@event.related_object.id}"
      handle_subscription_servicing_activated(@event.related_object.id)
    when 'v2.billing.cadence.billed'
      Rails.logger.info "Handling cadence billed event: #{@event.related_object.id}"
      refresh_account_subscription_details(@event.related_object.id)
    else
      { success: true }
    end
  rescue StandardError => e
    Rails.logger.error "Error processing V2 webhook: #{e.message}"
    { success: false, error: e.message }
  end

  private

  def account
    @account ||= begin
      related_object = @event.related_object
      subscription_id = related_object.id

      customer_id = fetch_customer_id_from_subscription(subscription_id)
      found_account = Account.find_by("custom_attributes->>'stripe_customer_id' = ?", customer_id) if customer_id.present?

      Rails.logger.warn "Could not find account for subscription #{subscription_id}" if found_account.blank?

      found_account
    end
  end

  def fetch_customer_id_from_subscription(subscription_id)
    subscription = StripeV2Client.request(
      :get,
      "/v2/billing/pricing_plan_subscriptions/#{subscription_id}",
      {},
      stripe_api_options
    )
    return nil unless subscription&.billing_cadence

    cadence = StripeV2Client.request(
      :get,
      "/v2/billing/cadences/#{subscription.billing_cadence}",
      {},
      stripe_api_options
    )
    cadence.payer&.customer
  end

  def handle_subscription_servicing_activated(subscription_id)
    Enterprise::Billing::V2::SubscriptionProvisioningService
      .new(account: account)
      .provision(subscription_id: subscription_id)
  end

  def refresh_account_subscription_details(_cadence_id)
    Enterprise::Billing::V2::SubscriptionProvisioningService
      .new(account: account)
      .refresh
  end

  def stripe_api_options
    { api_key: ENV.fetch('STRIPE_SECRET_KEY', nil), stripe_version: '2025-08-27.preview' }
  end
end
