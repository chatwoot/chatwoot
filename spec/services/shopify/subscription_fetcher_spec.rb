require 'rails_helper'

RSpec.describe Shopify::SubscriptionFetcher do
  let(:account) do
    create(:account, internal_attributes: { 'billing_provider' => 'shopify', 'signup_source' => 'shopify' })
  end
  let(:snapshot) do
    Shopify::SubscriptionSnapshot.from_h(
      'state' => 'active',
      'plan_handles' => ['shopify-basic'],
      'verified_at' => '2026-07-29T10:00:00Z'
    )
  end
  let(:client) { instance_double(Shopify::PartnerClient) }
  let(:shop_identity) { instance_double(Shopify::ShopIdentity, shop_id: 'gid://shopify/Shop/5678') }

  let!(:hook) do
    create(:integrations_hook, :shopify, account: account, settings: { 'shop_id' => 'gid://shopify/Shop/5678' })
  end

  before do
    allow(Shopify::FeatureGate).to receive(:enabled?).with(account: account).and_return(true)
    allow(Shopify::PartnerClient).to receive(:new).and_return(client)
    allow(Shopify::ShopIdentity).to receive(:new).and_return(shop_identity)
    allow(client).to receive(:subscription_snapshot).and_return(snapshot)
    allow(Rails.cache).to receive(:read)
    allow(Rails.cache).to receive(:write)
  end

  it 'caches a normalized snapshot for page loads' do
    verified_at = Time.zone.parse('2026-07-29T10:00:00Z')
    allow(Time).to receive(:current).and_return(verified_at)

    result = described_class.new(account: account).perform

    expect(result.to_h).to eq(snapshot.to_h)
    expect(client).to have_received(:subscription_snapshot).with(
      shop_id: 'gid://shopify/Shop/5678',
      verified_at: verified_at
    )
    expect(Rails.cache).to have_received(:write).with(
      "shopify:subscription_snapshot:account:#{account.id}",
      snapshot.to_h,
      expires_in: 2.minutes
    )
  end

  it 'timestamps the verification before provider identity lookup starts' do
    verified_at = Time.zone.parse('2026-07-29T10:00:00Z')
    call_order = []
    allow(Time).to receive(:current) do
      call_order << :timestamp
      verified_at
    end
    allow(shop_identity).to receive(:shop_id) do
      call_order << :identity_lookup
      'gid://shopify/Shop/5678'
    end

    described_class.new(account: account).perform(force: true)

    expect(call_order).to eq(%i[timestamp identity_lookup])
    expect(client).to have_received(:subscription_snapshot).with(
      shop_id: 'gid://shopify/Shop/5678',
      verified_at: verified_at
    )
  end

  it 'serializes provider verification with integration lifecycle changes' do
    association = account.hooks
    allow(association).to receive(:find_by!).and_return(hook)
    allow(hook).to receive(:with_lock).and_call_original

    described_class.new(account: account).perform(force: true)

    expect(hook).to have_received(:with_lock)
  end

  it 'does not verify a subscription after credentials are revoked while waiting for the hook lock' do
    association = account.hooks
    allow(association).to receive(:find_by!).and_return(hook)
    allow(hook).to receive(:with_lock) do |&block|
      hook.assign_attributes(status: :disabled, access_token: nil)
      block.call
    end

    expect do
      described_class.new(account: account).perform(force: true)
    end.to raise_error(ActiveRecord::RecordNotFound, 'Shopify integration credentials are unavailable')
    expect(client).not_to have_received(:subscription_snapshot)
  end

  it 'returns a cached normalized snapshot without calling Shopify' do
    allow(Rails.cache).to receive(:read).and_return(snapshot.to_h)

    result = described_class.new(account: account).perform

    expect(result.to_h).to eq(snapshot.to_h)
    expect(client).not_to have_received(:subscription_snapshot)
  end

  it 'bypasses the cache when a fresh verification is required' do
    allow(Rails.cache).to receive(:read).and_return(snapshot.to_h)

    described_class.new(account: account).perform(force: true)

    expect(Rails.cache).not_to have_received(:read)
    expect(client).to have_received(:subscription_snapshot).with(
      shop_id: 'gid://shopify/Shop/5678',
      verified_at: instance_of(ActiveSupport::TimeWithZone)
    )
  end

  it 'serializes provider refreshes on the Shopify hook' do
    fetcher = described_class.new(account: account)
    shopify_hook = account.hooks.find_by!(app_id: 'shopify')
    allow(fetcher).to receive(:hook).and_return(shopify_hook)
    expect(shopify_hook).to receive(:with_lock).and_yield

    fetcher.perform(force: true)

    expect(Rails.cache).to have_received(:write).with(
      "shopify:subscription_snapshot:account:#{account.id}",
      snapshot.to_h,
      expires_in: 2.minutes
    )
  end

  it 'does not call Shopify when the feature gate is disabled' do
    allow(Shopify::FeatureGate).to receive(:enabled?).with(account: account).and_return(false)

    expect do
      described_class.new(account: account).perform
    end.to raise_error(described_class::NotEligible, 'Shopify subscription lookup is disabled')
    expect(client).not_to have_received(:subscription_snapshot)
  end

  it 'does not call Shopify for a Stripe-billed account' do
    allow(account).to receive(:billing_provider).and_return('stripe')

    expect do
      described_class.new(account: account).perform
    end.to raise_error(described_class::NotEligible, 'Account is not billed through Shopify')
    expect(client).not_to have_received(:subscription_snapshot)
  end
end
