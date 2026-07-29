require 'rails_helper'

RSpec.describe Enterprise::Billing::ShopifySubscriptionSyncJob do
  let(:account) do
    create(
      :account,
      internal_attributes: {
        'billing_provider' => 'shopify',
        'signup_source' => 'shopify'
      }
    )
  end
  let(:sync_service) { instance_double(Enterprise::Billing::ShopifySubscriptionSyncService, perform: nil) }

  before do
    account.enable_features!('shopify_integration')
    allow(GlobalConfigService).to receive(:load).and_call_original
    allow(GlobalConfigService).to receive(:load)
      .with('ENABLE_SHOPIFY_INTEGRATION', 'false')
      .and_return(true)
  end

  it 'runs subscription reconciliation for a feature-enabled account' do
    allow(Enterprise::Billing::ShopifySubscriptionSyncService).to receive(:new)
      .with(account: account)
      .and_return(sync_service)

    described_class.perform_now(account.id)

    expect(sync_service).to have_received(:perform)
  end

  it 'does not run subscription reconciliation when the account gate is disabled' do
    account.disable_features!('shopify_integration')
    expect(Enterprise::Billing::ShopifySubscriptionSyncService).not_to receive(:new)

    described_class.perform_now(account.id)
  end

  it 'uses the scheduled jobs queue' do
    expect(described_class.queue_name).to eq('scheduled_jobs')
  end
end
