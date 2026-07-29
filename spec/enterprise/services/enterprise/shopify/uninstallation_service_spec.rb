require 'rails_helper'

RSpec.describe Shopify::UninstallationService do
  let(:account) do
    create(
      :account,
      internal_attributes: {
        'billing_provider' => 'shopify',
        'signup_source' => 'shopify'
      },
      custom_attributes: {
        'plan_name' => 'Shopify Basic',
        'subscription_status' => 'active',
        'shopify_subscription_snapshot' => {
          'state' => 'active',
          'plan_handles' => ['shopify-basic'],
          'shop_id' => 'gid://shopify/Shop/5678',
          'shop_domain' => 'test-store.myshopify.com'
        }
      }
    )
  end
  let(:occurred_at) { Time.iso8601('2026-07-29T10:01:00.123456Z') }
  let(:hook) do
    create(
      :integrations_hook,
      :shopify,
      account: account,
      access_token: 'shopify-access-token',
      settings: {
        'scope' => 'read_customers,read_orders',
        'connected_at' => '2026-07-29T09:00:00.000000Z',
        'installation_id' => SecureRandom.uuid
      }
    )
  end
  let(:sync_service) { instance_double(Enterprise::Billing::ShopifySubscriptionSyncService) }

  before do
    account.enable_features!('shopify_integration')
    allow(GlobalConfigService).to receive(:load).and_call_original
    allow(GlobalConfigService).to receive(:load)
      .with('ENABLE_SHOPIFY_INTEGRATION', 'false')
      .and_return(true)
    allow(Enterprise::Billing::ShopifySubscriptionSyncService).to receive(:new)
      .with(account: account)
      .and_return(sync_service)
  end

  it 'expires billing through the sync service and revokes stored credentials' do
    captured_snapshot = nil
    allow(sync_service).to receive(:perform) do |snapshot:|
      captured_snapshot = snapshot
    end

    described_class.new(hook: hook, occurred_at: occurred_at).perform

    expect(captured_snapshot.to_h).to include(
      'state' => 'expired',
      'plan_handles' => [],
      'shop_id' => 'gid://shopify/Shop/5678',
      'shop_domain' => 'test-store.myshopify.com',
      'latest_event' => {
        'state' => 'RELATIONSHIP_UNINSTALLED',
        'occurred_at' => occurred_at.iso8601(6)
      }
    )
    expect(hook.reload).to have_attributes(
      status: 'disabled',
      access_token: nil,
      settings: {}
    )
  end

  it 'still revokes credentials when billing reconciliation fails' do
    allow(sync_service).to receive(:perform).and_raise(StandardError, 'sync failed')

    expect do
      described_class.new(hook: hook, occurred_at: occurred_at).perform
    end.to raise_error(StandardError, 'sync failed')

    expect(hook.reload).to have_attributes(
      status: 'disabled',
      access_token: nil,
      settings: {}
    )
  end
end
