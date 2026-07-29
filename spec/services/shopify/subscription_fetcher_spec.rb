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

  before do
    create(:integrations_hook, :shopify, account: account, settings: { 'shop_id' => 'gid://shopify/Shop/5678' })
    allow(Shopify::FeatureGate).to receive(:enabled?).with(account: account).and_return(true)
    allow(Shopify::PartnerClient).to receive(:new).and_return(client)
    allow(client).to receive(:subscription_snapshot).and_return(snapshot)
    allow(Rails.cache).to receive(:read)
    allow(Rails.cache).to receive(:write)
  end

  it 'caches a normalized snapshot for page loads' do
    result = described_class.new(account: account).perform

    expect(result.to_h).to eq(snapshot.to_h)
    expect(client).to have_received(:subscription_snapshot).with(shop_id: 'gid://shopify/Shop/5678')
    expect(Rails.cache).to have_received(:write).with(
      "shopify:subscription_snapshot:account:#{account.id}",
      snapshot.to_h,
      expires_in: 2.minutes
    )
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
    expect(client).to have_received(:subscription_snapshot)
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
