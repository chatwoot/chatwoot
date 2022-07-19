class Enterprise::Billing::CreateStripeCustomerService
  pattr_initialize [:account!]

  DEFAULT_QUANTITY = 2

  def perform
    customer = Stripe::Customer.create({ name: account.name, email: billing_email })
    subscription = Stripe::Subscription.create(
      {
        customer: customer.id,
        items: [{ price: price_id, quantity: default_quantity }]
      }
    )
    account.update!(
      custom_attributes: {
        stripe_customer_id: customer.id,
        stripe_price_id: subscription['plan']['id'],
        stripe_product_id: subscription['plan']['product'],
        plan_name: default_plan['name'],
        subscribed_quantity: subscription['quantity']
      }
    )
  end

  private

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
end
