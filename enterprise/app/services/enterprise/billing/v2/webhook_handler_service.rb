class Enterprise::Billing::V2::WebhookHandlerService
  include Enterprise::Billing::Concerns::StripeV2ClientHelper

  def perform(event:)
    @event = event
    raise StandardError, 'Event is required' if @event.blank?
    raise StandardError, 'Account not found' if account.blank?

    case @event.type
    when 'v2.billing.pricing_plan_subscription.servicing_activated'
      Rails.logger.info "Handling subscription servicing activated event: #{@event.related_object.id}"
      handle_subscription_servicing_activated(@event.related_object.id)
    when 'v2.billing.cadence.billed'
      Rails.logger.info "Handling cadence billed event: #{@event.related_object.id}"
      refresh_account_subscription_details(@event.related_object.id)
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: account).capture_exception
    raise
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
    subscription = retrieve_pricing_plan_subscription(subscription_id)
    return nil unless subscription&.billing_cadence

    cadence = retrieve_billing_cadence(subscription.billing_cadence)
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
end
