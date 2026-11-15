module Enterprise::Internal::TriggerHourlyScheduledItemsJob
  def perform
    super

    Captain::Mcp::ToolChangeCheckJob.perform_later

    return unless Shopify::FeatureGate.globally_enabled?

    Enterprise::Billing::ShopifySubscriptionReconciliationJob.perform_later
  end
end
