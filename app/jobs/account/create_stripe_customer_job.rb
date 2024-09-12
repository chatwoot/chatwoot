class Account::CreateStripeCustomerJob < ApplicationJob
  queue_as :default

  def perform(account)
    Billing::CreateStripeCustomerService.new(account: account).perform
  end
end
