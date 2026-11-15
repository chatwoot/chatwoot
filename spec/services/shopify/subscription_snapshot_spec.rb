require 'rails_helper'

RSpec.describe Shopify::SubscriptionSnapshot do
  let(:verified_at) { Time.zone.parse('2026-07-29 10:00:00 UTC') }
  let(:active_subscription) do
    {
      'shop' => {
        'id' => 'gid://shopify/Shop/5678',
        'myshopifyDomain' => 'example.myshopify.com'
      },
      'billingPeriod' => 'EVERY_30_DAYS',
      'cancelAtEndOfCycle' => false,
      'trialEndsAt' => nil,
      'currentBillingCycle' => {
        'startTime' => '2026-07-01T00:00:00Z',
        'endTime' => '2026-08-01T00:00:00Z'
      },
      'items' => [{
        'handle' => 'shopify-basic',
        'description' => 'Shopify Basic',
        'price' => {
          'active' => true,
          'currency' => 'USD',
          'amount' => '29.00'
        }
      }]
    }
  end

  it 'normalizes an active subscription' do
    snapshot = described_class.from_partner_response(
      {
        'activeSubscription' => active_subscription,
        'events' => { 'edges' => [] }
      },
      verified_at: verified_at
    )

    expect(snapshot).to be_entitled
    expect(snapshot.to_h).to include(
      'state' => 'active',
      'plan_handles' => ['shopify-basic'],
      'plan_name' => 'Shopify Basic',
      'amount' => '29.00',
      'currency' => 'USD',
      'verified_at' => '2026-07-29T10:00:00.000000Z'
    )
  end

  it 'normalizes a trial subscription' do
    subscription = active_subscription.merge('trialEndsAt' => '2026-08-10T00:00:00Z', 'currentBillingCycle' => nil)
    snapshot = described_class.from_partner_response(
      {
        'activeSubscription' => subscription,
        'events' => { 'edges' => [] }
      },
      verified_at: verified_at
    )

    expect(snapshot).to have_attributes(state: 'trialing', entitled?: true)
  end

  it 'normalizes an elapsed trial as active' do
    subscription = active_subscription.merge('trialEndsAt' => '2026-07-28T00:00:00Z')
    snapshot = described_class.from_partner_response(
      {
        'activeSubscription' => subscription,
        'events' => { 'edges' => [] }
      },
      verified_at: verified_at
    )

    expect(snapshot).to have_attributes(state: 'active', entitled?: true)
  end

  it 'prioritizes scheduled cancellation while a trial is active' do
    subscription = active_subscription.merge(
      'cancelAtEndOfCycle' => true,
      'trialEndsAt' => '2026-08-10T00:00:00Z'
    )
    snapshot = described_class.from_partner_response(
      {
        'activeSubscription' => subscription,
        'events' => { 'edges' => [] }
      },
      verified_at: verified_at
    )

    expect(snapshot).to have_attributes(state: 'cancelled', entitled?: true)
  end

  it 'normalizes a completed cancellation as expired' do
    latest_event = {
      'state' => 'CANCELED',
      'cancelEffectiveOn' => '2026-07-28',
      'occurredAt' => '2026-07-28T00:00:00Z'
    }

    snapshot = described_class.from_partner_response(
      {
        'activeSubscription' => nil,
        'events' => { 'edges' => [{ 'node' => latest_event }] }
      },
      verified_at: verified_at
    )

    expect(snapshot).to have_attributes(state: 'expired', entitled?: false)
    expect(snapshot.to_h['latest_event']).to eq(
      'state' => 'CANCELED',
      'cancel_effective_on' => '2026-07-28',
      'occurred_at' => '2026-07-28T00:00:00Z'
    )
  end

  it 'normalizes a missing contract separately from an expired contract' do
    snapshot = described_class.from_partner_response(
      {
        'activeSubscription' => nil,
        'events' => { 'edges' => [] }
      },
      verified_at: verified_at
    )

    expect(snapshot).to have_attributes(state: 'missing', entitled?: false)
  end
end
