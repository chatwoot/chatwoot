require 'rails_helper'

describe Enterprise::Billing::HandleStripeEventService do
  let(:business_subscription) do
    {
      id: 'sub_123',
      customer: 'cus_123',
      status: 'active',
      quantity: 45,
      current_period_end: 1_790_845_600,
      cancel_at: nil,
      cancel_at_period_end: false,
      plan: { id: 'price_business', product: 'prod_business', currency: 'usd' }
    }
  end
  let!(:account) do
    create(:account,
           custom_attributes: { 'stripe_customer_id' => 'cus_123', 'plan_name' => 'Business', 'subscription_status' => 'active' },
           limits: { 'captain_responses' => 500 })
  end

  def handle(status, previous_status)
    subscription = business_subscription.merge(status: status)
    allow(Stripe::Subscription).to receive(:retrieve).and_return(Stripe::Subscription.construct_from(subscription))
    event = Stripe::Event.construct_from(
      id: "evt_#{status}",
      type: 'customer.subscription.updated',
      api_version: '2024-06-20',
      data: { object: subscription, previous_attributes: { status: previous_status } }
    )
    described_class.new.perform(event: event)
    account.reload
  end

  before do
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
    allow(Stripe::Subscription).to receive(:create)
    create(:installation_config, name: 'CHATWOOT_CLOUD_PLANS', value: [
             { 'name' => 'Hacker', 'product_id' => ['prod_hacker'], 'price_ids' => ['price_hacker'] },
             { 'name' => 'Business', 'product_id' => ['prod_business'], 'price_ids' => ['price_business'] }
           ])
    create(:installation_config, name: 'CAPTAIN_CLOUD_PLAN_LIMITS',
                                 value: { 'hacker' => { 'responses' => 0 }, 'business' => { 'responses' => 500 } })
    handle('active', nil)
  end

  it 'moves an unpaid subscription to the free plan without replacing the subscription' do
    handle('unpaid', 'past_due')

    expect(account.custom_attributes).to include('plan_name' => 'Hacker', 'subscription_status' => 'unpaid')
    expect(account.feature_enabled?('sla')).to be(false)
    expect(account.limits['captain_responses']).to eq(0)
    expect(Stripe::Subscription).not_to have_received(:create)
  end

  it 'restores the paid plan when the unpaid invoice is paid late' do
    handle('unpaid', 'past_due')
    handle('active', 'unpaid')

    expect(account.custom_attributes).to include('plan_name' => 'Business', 'subscription_status' => 'active')
    expect(account.feature_enabled?('sla')).to be(true)
    expect(account.limits['captain_responses']).to eq(500)
  end

  it 'keeps the paid plan while payment retries are still running' do
    handle('past_due', 'active')

    expect(account.custom_attributes).to include('plan_name' => 'Business', 'subscription_status' => 'past_due')
    expect(account.feature_enabled?('sla')).to be(true)
  end
end
