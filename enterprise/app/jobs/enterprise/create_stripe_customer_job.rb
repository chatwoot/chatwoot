class Enterprise::CreateStripeCustomerJob < ApplicationJob
  queue_as :default

  def perform(account)
    # Use V1 service - creates customer and stores customer_id
    Enterprise::Billing::CreateStripeCustomerService.new(account: account).perform
  end
end
