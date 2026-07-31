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
  let(:shopify_plans) do
    [
      {
        'name' => 'Shopify Basic',
        'handle' => 'shopify-basic',
        'features' => %w[audit_logs saml],
        'limits' => { 'agents' => 5, 'inboxes' => 10 }
      }
    ]
  end
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

  it 'expires billing and deletes a redacted hook when the account feature is disabled' do
    create(:installation_config, name: 'CHATWOOT_SHOPIFY_PLANS', value: shopify_plans, locked: true)
    account.enable_features!('audit_logs', 'saml')
    account.disable_features!('shopify_integration')
    allow(Enterprise::Billing::ShopifySubscriptionSyncService).to receive(:new)
      .with(account: account)
      .and_call_original
    hook

    expect do
      described_class.new(hook: hook, occurred_at: occurred_at, delete_hook: true).perform
    end.to change(Integrations::Hook, :count).by(-1)
    expect(account.reload).to be_suspended
    expect(account.custom_attributes).to include(
      'plan_name' => nil,
      'subscription_status' => 'expired'
    )
    expect(account.custom_attributes['shopify_subscription_snapshot']).not_to include('shop_id', 'shop_domain')
    expect(account).not_to be_feature_enabled('audit_logs')
    expect(account).not_to be_feature_enabled('saml')
    expect(account).not_to be_feature_enabled('shopify_integration')
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

  it 'does not reconcile billing when credential revocation fails' do
    allow(hook).to receive(:update!).and_raise(ActiveRecord::RecordNotSaved, 'credential revocation failed')
    expect(sync_service).not_to receive(:perform)

    expect do
      described_class.new(hook: hook, occurred_at: occurred_at).perform
    end.to raise_error(ActiveRecord::RecordNotSaved, 'credential revocation failed')
  end

  it 'expires billing and revokes credentials when the account feature is disabled' do
    create(:installation_config, name: 'CHATWOOT_SHOPIFY_PLANS', value: shopify_plans, locked: true)
    account.enable_features!('audit_logs', 'saml')
    account.disable_features!('shopify_integration')
    allow(Enterprise::Billing::ShopifySubscriptionSyncService).to receive(:new)
      .with(account: account)
      .and_call_original

    described_class.new(hook: hook, occurred_at: occurred_at).perform

    expect(account.reload).to be_suspended
    expect(account.custom_attributes).to include(
      'plan_name' => nil,
      'subscription_status' => 'expired'
    )
    expect(account).not_to be_feature_enabled('audit_logs')
    expect(account).not_to be_feature_enabled('saml')
    expect(account).not_to be_feature_enabled('shopify_integration')
    expect(hook.reload).to have_attributes(
      status: 'disabled',
      access_token: nil,
      settings: {}
    )
  end
end
