class Enterprise::Billing::CreateStripeCustomerService
  include Enterprise::Billing::Concerns::PlanFeatureManager

  pattr_initialize [:account!]

  DEFAULT_QUANTITY = 2

  def perform
    return if existing_subscription?

    customer_id = prepare_customer_id

    if billing_v2_enabled? && v2_configs_present?
      update_account_for_v2_billing(customer_id)
      enable_plan_specific_features(default_plan['name'])
    elsif default_plan.present?
      subscription = create_subscription(customer_id)
      update_account_with_subscription(customer_id, subscription)
    else
      # Minimal setup when configs are missing
      account.update!(custom_attributes: { stripe_customer_id: customer_id })
    end
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
    @default_plan ||= installation_config&.value&.first
  end

  def price_id
    price_ids = default_plan['price_ids']
    price_ids.first
  end

  def billing_v2_enabled?
    ENV.fetch('STRIPE_BILLING_V2_ENABLED', 'false') == 'true'
  end

  def v2_configs_present?
    InstallationConfig.find_by(name: 'STRIPE_HACKER_PLAN_ID').present? &&
      default_plan.present?
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

  def create_subscription(customer_id)
    Stripe::Subscription.create(
      customer: customer_id,
      items: [{ price: price_id, quantity: default_quantity }]
    )
  end

  def update_account_for_v2_billing(customer_id)
    hacker_plan_config = InstallationConfig.find_by(name: 'STRIPE_HACKER_PLAN_ID')

    attributes = { stripe_customer_id: customer_id }

    if hacker_plan_config&.value.present?
      attributes.merge!(
        stripe_pricing_plan_id: hacker_plan_config.value,
        plan_name: 'Hacker',
        subscribed_quantity: DEFAULT_QUANTITY
      )
    end

    account.update!(custom_attributes: attributes)
  end

  def update_account_with_subscription(customer_id, subscription)
    account.update!(
      custom_attributes: {
        stripe_customer_id: customer_id,
        stripe_price_id: subscription['plan']['id'],
        stripe_product_id: subscription['plan']['product'],
        plan_name: default_plan['name'],
        subscribed_quantity: subscription['quantity']
      }
    )
  end
end
