class Enterprise::Billing::CreateStripeCustomerService
  include BillingHelper

  pattr_initialize [:account!]

  DEFAULT_QUANTITY = 2

  def perform
    active_sub = active_subscription
    return false if active_sub && !default_plan_subscription?(active_sub)

    # Only a brand-new customer gets the trial; accounts falling back to the free plan after a cancellation don't.
    start_trial = account.custom_attributes['stripe_customer_id'].blank? && Enterprise::Billing::TrialService.enabled?
    customer_id = prepare_customer_id
    subscription = active_sub || create_subscription(customer_id, start_trial)
    custom_attributes = build_custom_attributes(customer_id, subscription)
    custom_attributes['trial_started_at'] = Time.current if start_trial
    custom_attributes.except!('is_creating_customer')

    account.update!(custom_attributes: custom_attributes)
    Enterprise::Billing::ReconcilePlanFeaturesService.new(account: account).perform
    true
  end

  private

  def create_subscription(customer_id, start_trial)
    params = { customer: customer_id, items: [{ price: price_id, quantity: default_quantity }] }
    params[:trial_period_days] = Enterprise::Billing::TrialService::TRIAL_DAYS if start_trial
    Stripe::Subscription.create(params)
  end

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

  # Without a status filter Stripe lists every subscription that isn't cancelled, so a trialing one is found too.
  def active_subscription
    stripe_customer_id = account.custom_attributes['stripe_customer_id']
    return nil if stripe_customer_id.blank?

    Stripe::Subscription.list({ customer: stripe_customer_id, limit: 1 }).data.first
  end

  def default_plan_subscription?(subscription)
    Enterprise::Billing::PlanConfiguration.plan_contains_product_id?(default_plan, subscription['plan']['product'])
  end

  def build_custom_attributes(customer_id, subscription)
    (account.custom_attributes || {}).merge(
      'stripe_customer_id' => customer_id,
      'stripe_price_id' => subscription['plan']['id'],
      'stripe_product_id' => subscription['plan']['product'],
      'plan_name' => default_plan['name'],
      'subscribed_quantity' => subscription['quantity'],
      'subscription_status' => subscription['status'],
      'subscription_ends_on' => subscription_ends_on(subscription),
      'subscription_cancels_on' => subscription_cancels_on(subscription),
      'trial_ends_at' => subscription['trial_end'] && Time.zone.at(subscription['trial_end']),
      'billing_currency' => billing_currency_for(subscription)
    )
  end

  # Persist the currency Stripe actually billed, read straight from the price; the
  # requested currency may lack a configured price and fall back to usd.
  def billing_currency_for(subscription)
    Enterprise::Billing::Currencies.to_supported(subscription['plan']['currency'])
  end
end
