class Enterprise::Billing::CreateStripeCustomerService
  include BillingHelper

  pattr_initialize [:account!]

  DEFAULT_QUANTITY = 2

  def perform
    existing_sub = existing_subscription
    return false if existing_sub && !default_plan_subscription?(existing_sub)

    customer_id = prepare_customer_id
    subscription = existing_sub || Stripe::Subscription.create(customer: customer_id, items: [{ price: price_id, quantity: default_quantity }])
    custom_attributes = build_custom_attributes(customer_id, subscription)
    custom_attributes.except!('is_creating_customer')

    account.update!(custom_attributes: custom_attributes)
    Enterprise::Billing::ReconcilePlanFeaturesService.new(account: account).perform
    true
  end

  private

  def prepare_customer_id
    customer_id = account.custom_attributes['stripe_customer_id']
    customer_id = Stripe::Customer.create(customer_params).id if customer_id.blank?
    customer_id
  end

  # Only currencies that need a country override (e.g. BRL/PIX) set address/locale; usd keeps Stripe defaults.
  def customer_params
    params = { name: account.name, email: billing_email }
    country = Enterprise::Billing::Currencies.country_for(account.billing_currency)
    return params if country.blank?

    params.merge(
      address: { country: country },
      preferred_locales: [Enterprise::Billing::Currencies.preferred_locale_for(account.billing_currency)]
    )
  end

  def default_quantity
    default_plan['default_quantity'] || DEFAULT_QUANTITY
  end

  def billing_email
    account.administrators.first.email
  end

  def default_plan
    @default_plan ||= Enterprise::Billing::PlanConfiguration.default_plan
  end

  def price_id
    Enterprise::Billing::PlanConfiguration.price_id_for(default_plan, account.billing_currency)
  end

  def existing_subscription
    stripe_customer_id = account.custom_attributes['stripe_customer_id']
    return nil if stripe_customer_id.blank?

    # The default Stripe list excludes canceled subscriptions but retains those
    # still recovering payment. Never replace a past_due paid plan with a free one.
    subscriptions = Stripe::Subscription.list(
      {
        customer: stripe_customer_id,
        limit: 100
      }
    ).auto_paging_each.reject { |subscription| subscription['status'] == 'incomplete_expired' }
    subscriptions.find { |subscription| !default_plan_subscription?(subscription) } || subscriptions.first
  end

  def default_plan_subscription?(subscription)
    Enterprise::Billing::PlanConfiguration.plan_contains_product_id?(default_plan, subscription_plan(subscription)['product'])
  end

  def build_custom_attributes(customer_id, subscription)
    (account.custom_attributes || {}).merge(
      'stripe_customer_id' => customer_id,
      'stripe_subscription_id' => subscription['id'],
      'stripe_price_id' => subscription_plan(subscription)['id'],
      'stripe_product_id' => subscription_plan(subscription)['product'],
      'plan_name' => default_plan['name'],
      'subscribed_quantity' => subscription_quantity(subscription),
      'subscription_status' => subscription['status'],
      'subscription_period_start' => subscription_period_start(subscription),
      'subscription_ends_on' => subscription_ends_on(subscription),
      'subscription_cancels_on' => subscription_cancels_on(subscription),
      'billing_currency' => billing_currency_for(subscription)
    )
  end

  # Persist the currency Stripe actually billed, read straight from the price; the
  # requested currency may lack a configured price and fall back to usd.
  def billing_currency_for(subscription)
    Enterprise::Billing::Currencies.to_supported(subscription_plan(subscription)['currency'])
  end
end
