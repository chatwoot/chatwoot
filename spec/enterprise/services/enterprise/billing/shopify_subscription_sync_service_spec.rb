require 'rails_helper'

RSpec.describe Enterprise::Billing::ShopifySubscriptionSyncService do
  let(:account) do
    create(
      :account,
      internal_attributes: { 'billing_provider' => 'shopify', 'signup_source' => 'shopify' },
      custom_attributes: {
        'plan_name' => 'Shopify Basic',
        'subscription_status' => 'pending'
      }
    )
  end
  let(:shopify_plans) do
    [
      {
        'name' => 'Shopify Basic',
        'handle' => 'shopify-basic',
        'features' => %w[audit_logs],
        'limits' => { 'agents' => 5, 'inboxes' => 10 }
      },
      {
        'name' => 'Shopify Pro',
        'handle' => 'shopify-pro',
        'features' => %w[audit_logs saml],
        'limits' => { 'agents' => 10, 'inboxes' => 20 }
      }
    ]
  end
  let(:fetcher) { instance_double(Shopify::SubscriptionFetcher) }
  let(:verified_at) { '2026-07-29T10:00:00Z' }
  let(:active_snapshot) do
    Shopify::SubscriptionSnapshot.from_h(
      'state' => 'active',
      'plan_handles' => ['shopify-pro'],
      'currency' => 'USD',
      'verified_at' => verified_at
    )
  end
  let(:inactive_snapshot) do
    Shopify::SubscriptionSnapshot.from_h(
      'state' => 'expired',
      'plan_handles' => [],
      'currency' => nil,
      'verified_at' => verified_at
    )
  end

  before do
    plans_config = InstallationConfig.find_or_initialize_by(name: 'CHATWOOT_SHOPIFY_PLANS')
    plans_config.update!(value: shopify_plans, locked: true)
    allow(GlobalConfigService).to receive(:load).and_call_original
    allow(GlobalConfigService).to receive(:load)
      .with('ENABLE_SHOPIFY_INTEGRATION', 'false')
      .and_return(true)
    account.enable_features!('shopify_integration')
    allow(Shopify::SubscriptionFetcher).to receive(:new).with(account: account).and_return(fetcher)
  end

  it 'applies the verified Shopify plan and its entitlements' do
    allow(fetcher).to receive(:perform).with(force: true).and_return(active_snapshot)

    described_class.new(account: account).perform

    expect(account.reload.custom_attributes).to include(
      'plan_name' => 'Shopify Pro',
      'subscription_status' => 'active',
      'billing_currency' => 'USD',
      'shopify_subscription_verified_at' => verified_at
    )
    expect(account.custom_attributes['shopify_subscription_snapshot']).to eq(active_snapshot.to_h)
    expect(account).to be_active
    expect(account).to be_feature_enabled('audit_logs')
    expect(account).to be_feature_enabled('saml')
    expect(account).to be_feature_enabled('shopify_integration')
  end

  it 'applies a verified lifecycle snapshot without calling Shopify again' do
    expect(fetcher).not_to receive(:perform)

    described_class.new(account: account).perform(snapshot: inactive_snapshot)

    expect(account.reload).to be_suspended
    expect(account.custom_attributes).to include(
      'plan_name' => nil,
      'subscription_status' => 'expired',
      'shopify_subscription_verified_at' => verified_at
    )
  end

  it 'applies an inactive lifecycle snapshot when the Shopify account feature is disabled' do
    account.enable_features!('audit_logs', 'saml')
    account.disable_features!('shopify_integration')
    expect(fetcher).not_to receive(:perform)

    described_class.new(account: account).perform(snapshot: inactive_snapshot)

    expect(account.reload).to be_suspended
    expect(account.custom_attributes).to include(
      'plan_name' => nil,
      'subscription_status' => 'expired',
      'shopify_subscription_verified_at' => verified_at
    )
    expect(account).not_to be_feature_enabled('audit_logs')
    expect(account).not_to be_feature_enabled('saml')
    expect(account).not_to be_feature_enabled('shopify_integration')
  end

  it 'does not apply an entitled snapshot when the Shopify account feature is disabled' do
    account.disable_features!('shopify_integration')
    expect(fetcher).not_to receive(:perform)
    previous_attributes = account.custom_attributes.deep_dup

    expect(described_class.new(account: account).perform(snapshot: active_snapshot)).to be_nil

    expect(account.reload.custom_attributes).to eq(previous_attributes)
    expect(account).to be_active
  end

  it 'suspends a verified inactive account and removes plan entitlements' do
    account.enable_features!('audit_logs', 'saml')
    allow(fetcher).to receive(:perform).with(force: true).and_return(inactive_snapshot)

    described_class.new(account: account).perform

    expect(account.reload).to be_suspended
    expect(account.custom_attributes).to include(
      'plan_name' => nil,
      'subscription_status' => 'expired',
      'shopify_subscription_verified_at' => verified_at
    )
    expect(account.internal_attributes['shopify_billing_suspended']).to eq(account.suspension_history.last['suspended_at'])
    expect(account.suspension_history.last).to include(
      'category' => 'non_payment',
      'reason' => 'Shopify App Pricing subscription is inactive'
    )
    expect(account).not_to be_feature_enabled('audit_logs')
    expect(account).not_to be_feature_enabled('saml')
    expect(account).to be_feature_enabled('shopify_integration')
  end

  it 'does not add duplicate suspension events when reconciliation is repeated' do
    allow(fetcher).to receive(:perform).with(force: true).and_return(inactive_snapshot)

    2.times { described_class.new(account: account).perform }

    expect(account.reload.suspension_history.size).to eq(1)
  end

  it 'does not let an in-flight active verification restore entitlements after uninstall' do
    uninstall_snapshot = Shopify::SubscriptionSnapshot.from_h(
      inactive_snapshot.to_h.merge(
        'verified_at' => '2026-07-29T10:01:00Z',
        'latest_event' => {
          'state' => 'RELATIONSHIP_UNINSTALLED',
          'occurred_at' => '2026-07-29T10:00:30Z'
        }
      )
    )
    older_active_snapshot = Shopify::SubscriptionSnapshot.from_h(
      active_snapshot.to_h.merge('verified_at' => '2026-07-29T10:00:00Z')
    )
    expect(fetcher).not_to receive(:perform)

    described_class.new(account: account).perform(snapshot: uninstall_snapshot)
    result = described_class.new(account: account).perform(snapshot: older_active_snapshot)

    expect(result.to_h).to eq(uninstall_snapshot.to_h)
    expect(account.reload).to be_suspended
    expect(account.custom_attributes).to include(
      'plan_name' => nil,
      'subscription_status' => 'expired',
      'shopify_subscription_verified_at' => '2026-07-29T10:01:00Z'
    )
    expect(account).not_to be_feature_enabled('saml')
  end

  it 'restores access after a Shopify-owned billing suspension becomes active' do
    reactivated_snapshot = Shopify::SubscriptionSnapshot.from_h(
      active_snapshot.to_h.merge('verified_at' => '2026-07-29T10:01:00Z')
    )
    allow(fetcher).to receive(:perform).with(force: true).and_return(inactive_snapshot, reactivated_snapshot)

    described_class.new(account: account).perform
    described_class.new(account: account).perform

    expect(account.reload).to be_active
    expect(account.internal_attributes).not_to have_key('shopify_billing_suspended')
    expect(account.custom_attributes['plan_name']).to eq('Shopify Pro')
  end

  it 'does not reactivate an account suspended outside Shopify billing' do
    account.update!(status: :suspended)
    allow(fetcher).to receive(:perform).with(force: true).and_return(active_snapshot)

    described_class.new(account: account).perform

    expect(account.reload).to be_suspended
    expect(account.custom_attributes['plan_name']).to eq('Shopify Pro')
  end

  it 'does not reactivate an account manually suspended after a Shopify billing suspension' do
    reactivated_snapshot = Shopify::SubscriptionSnapshot.from_h(
      active_snapshot.to_h.merge('verified_at' => '2026-07-29T10:01:00Z')
    )
    allow(fetcher).to receive(:perform).with(force: true).and_return(inactive_snapshot, reactivated_snapshot)
    described_class.new(account: account).perform

    manual_suspension = {
      'category' => 'spam',
      'reason' => 'Manual review',
      'suspended_at' => 1.minute.from_now.iso8601
    }
    account.update!(
      status: :suspended,
      internal_attributes: account.internal_attributes.merge('suspensions' => account.suspension_history + [manual_suspension])
    )

    described_class.new(account: account).perform

    expect(account.reload).to be_suspended
    expect(account.internal_attributes).not_to have_key('shopify_billing_suspended')
  end

  it 'preserves the last verified state during a provider outage' do
    previous_attributes = account.custom_attributes.deep_dup
    allow(fetcher).to receive(:perform)
      .with(force: true)
      .and_raise(Shopify::PartnerClient::ProviderError, 'Shopify Partner API request failed')

    expect do
      described_class.new(account: account).perform
    end.to raise_error(Shopify::PartnerClient::ProviderError)

    expect(account.reload.custom_attributes).to eq(previous_attributes)
    expect(account).to be_active
  end

  it 'does not call Shopify or mutate the account when the feature gate is disabled' do
    allow(GlobalConfigService).to receive(:load)
      .with('ENABLE_SHOPIFY_INTEGRATION', 'false')
      .and_return(false)
    expect(fetcher).not_to receive(:perform)
    previous_attributes = account.custom_attributes.deep_dup

    expect(described_class.new(account: account).perform).to be_nil

    expect(account.reload.custom_attributes).to eq(previous_attributes)
  end

  it 'rejects an unknown active plan without changing prior entitlements' do
    unknown_snapshot = Shopify::SubscriptionSnapshot.from_h(
      'state' => 'active',
      'plan_handles' => ['unknown-plan'],
      'verified_at' => verified_at
    )
    allow(fetcher).to receive(:perform).with(force: true).and_return(unknown_snapshot)
    previous_attributes = account.custom_attributes.deep_dup

    expect do
      described_class.new(account: account).perform
    end.to raise_error(described_class::InvalidSubscription, 'Shopify subscription has an unknown plan handle')

    expect(account.reload.custom_attributes).to eq(previous_attributes)
  end

  it 'rejects multiple active plan handles' do
    multiple_snapshot = Shopify::SubscriptionSnapshot.from_h(
      'state' => 'active',
      'plan_handles' => %w[shopify-basic shopify-pro],
      'verified_at' => verified_at
    )
    allow(fetcher).to receive(:perform).with(force: true).and_return(multiple_snapshot)

    expect do
      described_class.new(account: account).perform
    end.to raise_error(described_class::InvalidSubscription, 'Shopify subscription must have exactly one active plan handle')
  end
end
