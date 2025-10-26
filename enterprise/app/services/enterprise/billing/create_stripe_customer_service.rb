class Enterprise::Billing::CreateStripeCustomerService
  pattr_initialize [:account!]

  def perform
    return if customer_exists?

    customer_id = create_customer
    save_customer_id(customer_id)
  end

  private

  def customer_exists?
    account.custom_attributes['stripe_customer_id'].present?
  end

  def create_customer
    customer = Stripe::Customer.create({ name: account.name, email: billing_email })
    customer.id
  end

  def save_customer_id(customer_id)
    account.update!(
      custom_attributes: {
        stripe_customer_id: customer_id
      }
    )
  end

  def billing_email
    account.administrators.first.email
  end
end
