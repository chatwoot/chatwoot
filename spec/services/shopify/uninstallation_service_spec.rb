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
  let(:hook) do
    create(
      :integrations_hook,
      :shopify,
      account: account,
      access_token: 'shopify-access-token',
      settings: { 'scope' => 'read_customers,read_orders' }
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

    described_class.new(hook: hook).perform

    expect(captured_snapshot.to_h).to include(
      'state' => 'expired',
      'plan_handles' => [],
      'shop_id' => 'gid://shopify/Shop/5678',
      'shop_domain' => 'test-store.myshopify.com',
      'latest_event' => hash_including('state' => 'RELATIONSHIP_UNINSTALLED')
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
      described_class.new(hook: hook).perform
    end.to raise_error(StandardError, 'sync failed')

    expect(hook.reload).to have_attributes(
      status: 'disabled',
      access_token: nil,
      settings: {}
    )
  end

  it 'does not mutate anything when the account feature is disabled' do
    hook
    account.disable_features!('shopify_integration')
    expect(sync_service).not_to receive(:perform)

    described_class.new(hook: hook).perform

    expect(hook.reload).to have_attributes(
      status: 'enabled',
      access_token: 'shopify-access-token'
    )
  end

  it 'removes the integration for accounts that are not billed through Shopify' do
    stripe_account = create(:account)
    stripe_account.enable_features!('shopify_integration')
    stripe_hook = create(:integrations_hook, :shopify, account: stripe_account)

    expect do
      described_class.new(hook: stripe_hook).perform
    end.to change(Integrations::Hook, :count).by(-1)
  end
end
