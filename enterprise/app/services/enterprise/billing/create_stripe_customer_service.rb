class Enterprise::Billing::CreateStripeCustomerService
  pattr_initialize [:account!]

  DEFAULT_QUANTITY = 2

  def perform
    return if existing_subscription?

    customer_id = prepare_customer_id
    subscription = Stripe::Subscription.create(customer: customer_id, items: [{ price: price_id, quantity: default_quantity }])
    custom_attributes = build_custom_attributes(customer_id, subscription)
    custom_attributes.except!('is_creating_customer')

    account.update!(custom_attributes: custom_attributes)
    Enterprise::Billing::ReconcilePlanFeaturesService.new(account: account).perform
  end

  private

  def prepare_customer_id
    customer_id = account.custom_attributes['stripe_customer_id']
    if customer_id.blank?
      customer = Stripe::Customer.create({ name: account.name, email: billing_email })
      customer_id = customer.id
    end
    customer_id
  end

  def default_quantity
    default_plan['default_quantity'] || DEFAULT_QUANTITY
  end

  def billing_email
    account.administrators.first.email
  end

  def default_plan
    installation_config = InstallationConfig.find_by(name: 'CHATWOOT_CLOUD_PLANS')
    @default_plan ||= installation_config.value.first
  end

  def price_id
    price_ids = default_plan['price_ids']
    price_ids.first
  end

  def existing_subscription?
    stripe_customer_id = account.custom_attributes['stripe_customer_id']
    return false if stripe_customer_id.blank?

    subscriptions = Stripe::Subscription.list(
      {
        customer: stripe_customer_id,
        status: 'active',
        limit: 1
      }
    )
    subscriptions.data.present?
  end

  def build_custom_attributes(customer_id, subscription)
    (account.custom_attributes || {}).merge(
      'stripe_customer_id' => customer_id,
      'stripe_price_id' => subscription['plan']['id'],
      'stripe_product_id' => subscription['plan']['product'],
      'plan_name' => default_plan['name'],
      'subscribed_quantity' => subscription['quantity'],
      'subscription_status' => subscription['status'],
      'subscription_ends_on' => subscription_ends_on(subscription)
    )
  end

  def subscription_ends_on(subscription)
    period_end = subscription['current_period_end']
    return if period_end.blank?

    Time.zone.at(period_end)
  end
end
