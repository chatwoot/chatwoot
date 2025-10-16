class Enterprise::CreateStripeCustomerJob < ApplicationJob
  queue_as :default

  def perform(account)
    # Check if this is a V2 billing account
    if v2_billing_enabled?
      # Use V2 service - creates customer and subscribes to free Hacker plan
      Enterprise::Billing::V2::CustomerCreationService.new(account: account).perform
    else
      # Use V1 service - legacy billing
      Enterprise::Billing::CreateStripeCustomerService.new(account: account).perform
    end
  end

  private

  def v2_billing_enabled?
    ENV.fetch('STRIPE_BILLING_V2_ENABLED', 'false') == 'true'
  end
end
