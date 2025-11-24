class Enterprise::Billing::HandleStripeEventService
  include Enterprise::Billing::Concerns::PlanFeatureManager
  include Enterprise::Billing::Concerns::StripeV2ClientHelper

  CLOUD_PLANS_CONFIG = 'CHATWOOT_CLOUD_PLANS'.freeze

  def perform(event:)
    @event = event

    case @event.type
    when 'customer.subscription.updated'
      process_subscription_updated
    when 'customer.subscription.deleted'
      process_subscription_deleted
    when 'billing.credit_grant.created'
      process_credit_grant_created
    else
      Rails.logger.debug { "Unhandled event type: #{event.type}" }
    end
  end

  private

  def process_subscription_updated
    plan = find_plan(subscription['plan']['product']) if subscription['plan'].present?

    # skipping self hosted plan events
    return if plan.blank? || account.blank?

    update_account_attributes(subscription, plan)
    plan_name = account.custom_attributes['plan_name']
    update_plan_features(plan_name)
    reset_captain_usage
  end

  def update_account_attributes(subscription, plan)
    # https://stripe.com/docs/api/subscriptions/object
    account.update(
      custom_attributes: {
        stripe_customer_id: subscription.customer,
        stripe_price_id: subscription['plan']['id'],
        stripe_product_id: subscription['plan']['product'],
        plan_name: plan['name'],
        subscribed_quantity: subscription['quantity'],
        subscription_status: subscription['status'],
        subscription_ends_on: Time.zone.at(subscription['current_period_end'])
      }
    )
  end

  def process_subscription_deleted
    # skipping self hosted plan events
    return if account.blank?

    Enterprise::Billing::CreateStripeCustomerService.new(account: account).perform
  end

  def subscription
    @subscription ||= @event.data.object
  end

  def account
    @account ||= begin
      customer_id = if @event.type.start_with?('billing.credit_grant')
                      # Credit grant events have customer directly on the object
                      @event.data.object.respond_to?(:customer) ? @event.data.object.customer : @event.data.object['customer']
                    else
                      # Subscription events have customer on subscription
                      subscription.customer
                    end

      Account.where("custom_attributes->>'stripe_customer_id' = ?", customer_id).first
    end
  end

  def find_plan(plan_id)
    cloud_plans = InstallationConfig.find_by(name: CLOUD_PLANS_CONFIG)&.value || []
    cloud_plans.find { |config| config['product_id'].include?(plan_id) }
  end

  def process_credit_grant_created
    grant_id = extract_credit_grant_id(@event.data.object)
    return if grant_id.blank?

    # Retrieve the full credit grant object from Stripe API
    grant = retrieve_credit_grant(grant_id)
    return if grant.blank?

    amount = extract_credit_amount(grant)
    return if amount.zero?

    grant_type = extract_grant_type(grant)
    service = Enterprise::Billing::V2::CreditManagementService.new(account: account)
    if grant_type == 'monetary'
      service.add_response_topup_credits(amount)
    else
      service.sync_monthly_response_credits(amount)
    end
  end

  def extract_credit_grant_id(grant_object)
    grant_object.respond_to?(:id) ? grant_object.id : grant_object['id']
  end

  def extract_grant_type(grant)
    amount_object = extract_attribute(grant, :amount)
    return 'monetary' if amount_object.blank?

    type = extract_attribute(amount_object, :type)
    return 'monetary' if type.blank?

    type
  end

  def extract_credit_amount(grant)
    # First, try to get credits from metadata
    metadata = extract_attribute(grant, :metadata)
    if metadata
      credits = extract_attribute(metadata, :credits)
      return credits.to_i if credits.present? && credits.to_i.positive?
    end
    amount = extract_attribute(grant, :amount)
    return 0 if amount.blank?

    custom_pricing_unit = extract_attribute(amount, :custom_pricing_unit)
    return 0 if custom_pricing_unit.blank?

    value = extract_attribute(custom_pricing_unit, :value)
    return 0 if value.blank?

    value.to_i
  end

  def extract_attribute(object, attribute)
    object.respond_to?(attribute) ? object.public_send(attribute) : object[attribute.to_s]
  end
end
