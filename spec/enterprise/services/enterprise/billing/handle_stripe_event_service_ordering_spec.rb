require 'rails_helper'

describe Enterprise::Billing::HandleStripeEventService do
  let(:prices) do
    {
      hacker: { id: 'price_hacker', product: 'prod_hacker', amount: 0, currency: 'usd' },
      startups: { id: 'price_startups', product: 'prod_startups', amount: 1900, currency: 'usd' },
      business: { id: 'price_business', product: 'prod_business', amount: 3900, currency: 'usd' }
    }
  end
  let!(:account) do
    create(:account,
           custom_attributes: { 'stripe_customer_id' => 'cus_123', 'plan_name' => 'Hacker' },
           limits: { 'captain_responses' => 0 })
  end

  def subscription_on(plan)
    {
      id: 'sub_123', object: 'subscription', customer: 'cus_123', status: 'active', quantity: 1,
      current_period_end: 1_790_845_600, cancel_at: nil, cancel_at_period_end: false, plan: prices.fetch(plan)
    }
  end

  # Delivers an event whose payload is on payload_plan while Stripe's subscription is now on current_plan.
  def deliver(payload_plan:, current_plan:, previous:)
    allow(Stripe::Subscription).to receive(:retrieve)
      .with('sub_123', { stripe_version: '2024-06-20' })
      .and_return(Stripe::Subscription.construct_from(subscription_on(current_plan)))
    event = Stripe::Event.construct_from(
      type: 'customer.subscription.updated',
      api_version: '2024-06-20',
      created: 1_763_000_000,
      data: { object: subscription_on(payload_plan), previous_attributes: previous }
    )
    described_class.new.perform(event: event)
    account.reload
  end

  before do
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
    create(:installation_config, name: 'CHATWOOT_CLOUD_PLANS', value: [
             { 'name' => 'Hacker', 'product_id' => ['prod_hacker'], 'price_ids' => ['price_hacker'] },
             { 'name' => 'Startups', 'product_id' => ['prod_startups'], 'price_ids' => ['price_startups'] },
             { 'name' => 'Business', 'product_id' => ['prod_business'], 'price_ids' => ['price_business'] }
           ])
    create(:installation_config, name: 'CAPTAIN_CLOUD_PLAN_LIMITS', value: {
             'hacker' => { 'responses' => 0 }, 'startups' => { 'responses' => 300 }, 'business' => { 'responses' => 500 }
           })
    conversion_service = instance_double(Internal::Accounts::CloudPlanActivationConversionService, perform: nil)
    allow(Internal::Accounts::CloudPlanActivationConversionService).to receive(:new).and_return(conversion_service)
  end

  it 'keeps the upgrade when the card-attached event from the same portal upgrade is retried hours later' do
    deliver(payload_plan: :startups, current_plan: :startups, previous: { plan: prices[:hacker] })
    deliver(payload_plan: :hacker, current_plan: :startups, previous: { default_payment_method: nil })

    expect(account.custom_attributes).to include('plan_name' => 'Startups', 'stripe_price_id' => 'price_startups')
    expect(account).to be_feature_enabled('api_and_webhooks')
    expect(account.limits['captain_responses']).to eq(300)
  end

  it 'keeps the newer plan when two plan changes are retried in reverse order' do
    deliver(payload_plan: :business, current_plan: :business, previous: { plan: prices[:startups] })
    deliver(payload_plan: :startups, current_plan: :business, previous: { plan: prices[:hacker] })

    expect(account.custom_attributes).to include('plan_name' => 'Business', 'stripe_price_id' => 'price_business')
    expect(account).to be_feature_enabled('sla')
    expect(account.limits['captain_responses']).to eq(500)
  end
end
