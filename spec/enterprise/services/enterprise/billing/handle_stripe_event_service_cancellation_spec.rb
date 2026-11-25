require 'rails_helper'

describe Enterprise::Billing::HandleStripeEventService do
  let(:period_end) { 1_790_845_600 }
  let(:cancels_on) { Time.zone.at(period_end).as_json }
  # Shape Stripe sends for a portal cancellation: the schedule lands on cancel_at, cancel_at_period_end stays false.
  let(:cancelling_subscription) do
    {
      customer: 'cus_123',
      status: 'active',
      quantity: 4,
      current_period_end: period_end,
      cancel_at: period_end,
      cancel_at_period_end: false,
      plan: { id: 'price_enterprise', product: 'prod_enterprise' }
    }
  end
  let!(:account) do
    create(:account,
           custom_attributes: { 'stripe_customer_id' => 'cus_123', 'plan_name' => 'Enterprise' },
           limits: { 'captain_responses' => 800 })
  end

  def handle(overrides = {}, previous: {}, type: 'customer.subscription.updated')
    event = Stripe::Event.construct_from(
      type: type,
      data: { object: cancelling_subscription.merge(overrides), previous_attributes: previous }
    )
    described_class.new.perform(event: event)
    account.reload
  end

  before do
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
    create(:installation_config, name: 'CHATWOOT_CLOUD_PLANS', value: [
             { 'name' => 'Hacker', 'product_id' => ['prod_hacker'], 'price_ids' => ['price_hacker'] },
             { 'name' => 'Enterprise', 'product_id' => ['prod_enterprise'], 'price_ids' => ['price_enterprise'] }
           ])
    create(:installation_config, name: 'CAPTAIN_CLOUD_PLAN_LIMITS',
                                 value: { 'hacker' => { 'responses' => 0 }, 'enterprise' => { 'responses' => 800 } })
  end

  it 'stores the cancellation date and keeps the plan active until then' do
    handle

    expect(account.custom_attributes).to include(
      'subscription_cancels_on' => cancels_on,
      'subscription_ends_on' => cancels_on,
      'subscription_status' => 'active',
      'plan_name' => 'Enterprise'
    )
    expect(account.limits['captain_responses']).to eq(800)
  end

  it 'falls back to the period end for classic billing, which only sets cancel_at_period_end' do
    handle({ cancel_at: nil, cancel_at_period_end: true })

    expect(account.custom_attributes['subscription_cancels_on']).to eq(cancels_on)
  end

  it 'clears the cancellation date when the customer resumes the subscription' do
    handle
    handle({ cancel_at: nil }, previous: { cancel_at: period_end })

    expect(account.custom_attributes['subscription_cancels_on']).to be_nil
  end

  it 'clears the cancellation date when a seat change resumes the subscription' do
    handle
    handle({ cancel_at: nil, quantity: 5 }, previous: { cancel_at: period_end, quantity: 4 })

    expect(account.custom_attributes).to include('subscription_cancels_on' => nil, 'subscribed_quantity' => 5)
    expect(account.limits['captain_responses']).to eq(800)
  end

  it 'clears the cancellation date when the subscription is finally deleted' do
    handle
    free_plan = { plan: { id: 'price_hacker', product: 'prod_hacker' }, quantity: 2, status: 'active',
                  current_period_end: period_end }.with_indifferent_access
    allow(Stripe::Subscription).to receive_messages(list: Struct.new(:data).new([]), create: free_plan)

    handle({ status: 'canceled' }, type: 'customer.subscription.deleted')

    expect(account.custom_attributes).to include('plan_name' => 'Hacker', 'subscription_cancels_on' => nil)
  end
end
