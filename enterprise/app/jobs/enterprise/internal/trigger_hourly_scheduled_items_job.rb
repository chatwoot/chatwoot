module Enterprise::Internal::TriggerHourlyScheduledItemsJob
  def perform
    super

    return unless Shopify::FeatureGate.globally_enabled?

    Enterprise::Billing::ShopifySubscriptionReconciliationJob.perform_later
  end
end
