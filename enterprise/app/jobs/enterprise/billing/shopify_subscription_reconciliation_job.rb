class Enterprise::Billing::ShopifySubscriptionReconciliationJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    return unless Shopify::FeatureGate.globally_enabled?

    Integrations::Hook.includes(:account).where(app_id: 'shopify', status: :enabled).find_each do |hook|
      account = hook.account
      next unless shopify_billed_account?(account)
      next unless Shopify::FeatureGate.enabled?(account: account)

      Enterprise::Billing::ShopifySubscriptionSyncJob.perform_later(account.id)
    end
  end

  private

  def shopify_billed_account?(account)
    account.billing_provider == 'shopify' && account.signup_source == 'shopify'
  end
end
