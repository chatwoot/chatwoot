class Enterprise::Billing::CreateStripeCustomerService
  include Enterprise::Billing::Concerns::PlanFeatureManager

  pattr_initialize [:account!]

  DEFAULT_QUANTITY = 2

  def perform
    return if existing_subscription?

    raise_config_error unless v2_configs_present?

    customer_id = prepare_customer_id
    update_account_for_v2_billing(customer_id)
    enable_plan_specific_features('Hacker')
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

  def v2_configs_present?
    InstallationConfig.find_by(name: 'STRIPE_HACKER_PLAN_ID').present?
  end

  def raise_config_error
    raise StandardError, I18n.t('errors.enterprise.billing.v2_configuration_required')
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

  def update_account_for_v2_billing(customer_id)
    hacker_plan_config = InstallationConfig.find_by(name: 'STRIPE_HACKER_PLAN_ID')

    attributes = {
      stripe_customer_id: customer_id,
      stripe_billing_version: 2
    }

    if hacker_plan_config&.value.present?
      attributes.merge!(
        stripe_pricing_plan_id: hacker_plan_config.value,
        plan_name: 'Hacker',
        subscribed_quantity: DEFAULT_QUANTITY
      )
    end

    account.update!(custom_attributes: attributes)
  end
end
