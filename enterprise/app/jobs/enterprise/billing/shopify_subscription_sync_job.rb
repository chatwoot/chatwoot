class Enterprise::Billing::ShopifySubscriptionSyncJob < ApplicationJob
  queue_as :scheduled_jobs

  discard_on ActiveRecord::RecordNotFound

  def perform(account_id)
    account = Account.find(account_id)
    return unless Shopify::FeatureGate.enabled?(account: account)

    Enterprise::Billing::ShopifySubscriptionSyncService.new(account: account).perform
  end
end
