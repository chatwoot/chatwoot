class Enterprise::CreateStripeCustomerJob < ApplicationJob
  queue_as :default

  def perform(account)
    Enterprise::Billing::CreateStripeCustomerService.new(account: account).perform
  end
end
