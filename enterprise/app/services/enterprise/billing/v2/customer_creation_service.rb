# Service to create Stripe customer for V2 billing with default Hacker pricing plan
class Enterprise::Billing::V2::CustomerCreationService < Enterprise::Billing::V2::BaseService
  def perform
    return { success: false, message: 'Customer already exists' } if customer_exists?
    return { success: false, message: 'Not a V2 billing account' } unless v2_enabled?
    return { success: false, message: 'Hacker pricing plan not configured' } unless hacker_plan_id

    with_locked_account do
      customer = create_stripe_customer
      return { success: false, message: 'Failed to create customer' } unless customer

      save_customer_id(customer.id)
      subscribe_to_hacker_pricing_plan(customer.id)
    end
  rescue Stripe::StripeError => e
    { success: false, message: e.message }
  end

  private

  def customer_exists?
    custom_attribute('stripe_customer_id').present?
  end

  def hacker_plan_id
    # Get Hacker plan pricing_plan_id from environment or installation config
    # Set via: ENV['STRIPE_HACKER_PRICING_PLAN_ID'] or InstallationConfig
    config = InstallationConfig.find_by(name: 'STRIPE_HACKER_PRICING_PLAN_ID')
    config&.value || ENV.fetch('STRIPE_HACKER_PRICING_PLAN_ID', nil)
  end

  def create_stripe_customer
    Stripe::Customer.create(
      {
        email: billing_email,
        name: account.name,
        description: "Chatwoot Account ##{account.id}",
        metadata: {
          account_id: account.id.to_s,
          account_name: account.name,
          billing_version: '2',
          plan_type: 'hacker'
        }
      },
      { api_key: ENV.fetch('STRIPE_SECRET_KEY', nil), stripe_version: '2025-08-27.preview' }
    )
  end

  def save_customer_id(customer_id)
    update_custom_attributes(
      'stripe_customer_id' => customer_id,
      'stripe_billing_version' => 2
    )
  end

  def subscribe_to_hacker_pricing_plan(customer_id)
    # Shared meter and event name are automatically loaded from ENV in SubscribeCustomerService
    Enterprise::Billing::V2::SubscribeCustomerService.new(account: account)
                                                     .subscribe_to_pricing_plan(
                                                       pricing_plan_id: hacker_plan_id,
                                                       customer_id: customer_id
                                                     )
  end

  def billing_email
    account.administrators.first&.email || "account_#{account.id}@chatwoot.com"
  end
end
