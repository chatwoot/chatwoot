class Billing::CreateStripeCustomerService
  pattr_initialize [:account!]

  def perform
    customer_id = prepare_customer_id
    subscription = Stripe::Subscription.create(
      {
        customer: customer_id,
        items: [{ price: price_id }]
      }
    )
    account.update!(
      custom_attributes: {
        stripe_customer_id: customer_id,
        stripe_price_id: subscription['plan']['id'],
        stripe_product_id: subscription['plan']['product'],
        stripe_subscription_id: subscription['id'],
        plan_name: default_plan
      }
    )
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

  def billing_email
    account.administrators.first.email
  end

  def default_plan
    subscription_plan = SubscriptionPlan.find_by(plan_name: 'Starter')
    return subscription_plan.plan_name if subscription_plan.present?
  end

  def price_id
    ENV.fetch('STRIPE_CHAT_STARTER_MONTHLY_PRICE_ID', nil)
  end
end
