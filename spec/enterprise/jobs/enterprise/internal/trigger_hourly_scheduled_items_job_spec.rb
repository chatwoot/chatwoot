require 'rails_helper'

RSpec.describe Internal::TriggerHourlyScheduledItemsJob do
  before do
    allow(Channels::Whatsapp::HealthSyncSchedulerJob).to receive(:perform_later)
    allow(Enterprise::Billing::ShopifySubscriptionReconciliationJob).to receive(:perform_later)
    allow(GlobalConfigService).to receive(:load).and_call_original
  end

  it 'enqueues Shopify reconciliation when the global feature gate is enabled' do
    create(:installation_config, name: 'ENABLE_SHOPIFY_INTEGRATION', value: true)

    described_class.perform_now

    expect(Enterprise::Billing::ShopifySubscriptionReconciliationJob).to have_received(:perform_later)
  end

  it 'does not enqueue Shopify reconciliation when the global feature gate is disabled' do
    create(:installation_config, name: 'ENABLE_SHOPIFY_INTEGRATION', value: false)

    described_class.perform_now

    expect(Enterprise::Billing::ShopifySubscriptionReconciliationJob).not_to have_received(:perform_later)
  end
end
