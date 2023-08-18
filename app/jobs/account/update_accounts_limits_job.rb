class Account::UpdateAccountsLimitsJob < ApplicationJob
  queue_as :default

  def perform(billing_product_price_id)
    billing_product_price = Enterprise::BillingProductPrice.find(billing_product_price_id)
    billing_product_price&.update_accounts_limits
  end
end
