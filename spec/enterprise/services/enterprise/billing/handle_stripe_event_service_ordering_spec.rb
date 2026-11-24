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

  let(:period_end) { 1_790_845_600 }
  let(:next_period_end) { 1_793_437_600 }

  def subscription_on(plan, period_ends_at = period_end)
    {
      id: 'sub_123', object: 'subscription', customer: 'cus_123', status: 'active', quantity: 1,
      current_period_end: period_ends_at, cancel_at: nil, cancel_at_period_end: false, plan: prices.fetch(plan)
    }
  end

  def updated_event(payload_plan, previous:, payload_period_end: period_end)
    Stripe::Event.construct_from(
      type: 'customer.subscription.updated',
      api_version: '2024-06-20',
      created: 1_763_000_000,
      data: { object: subscription_on(payload_plan, payload_period_end), previous_attributes: previous }
    )
  end

  # Delivers an event whose payload is on payload_plan while Stripe's subscription is now on current_plan.
  def deliver(payload_plan:, current_plan:, previous:, payload_period_end: period_end, current_period_end: period_end)
    allow(Stripe::Subscription).to receive(:retrieve)
      .with('sub_123', { stripe_version: '2024-06-20' })
      .and_return(Stripe::Subscription.construct_from(subscription_on(current_plan, current_period_end)))
    described_class.new.perform(event: updated_event(payload_plan, previous: previous, payload_period_end: payload_period_end))
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

  it 'keeps the upgrade when an older event from the same portal upgrade is retried hours later' do
    deliver(payload_plan: :startups, current_plan: :startups, previous: { plan: prices[:hacker] })
    deliver(payload_plan: :hacker, current_plan: :startups, previous: { default_payment_method: nil })

    expect(account.custom_attributes['plan_name']).to eq('Startups')
    expect(account).to be_feature_enabled('api_and_webhooks')
    expect(account.limits['captain_responses']).to eq(300)
    expect(Internal::Accounts::CloudPlanActivationConversionService).to have_received(:new).once
  end

  it 'grants the new plan credits once when the events arrive in the other order' do
    deliver(payload_plan: :hacker, current_plan: :startups, previous: { default_payment_method: nil })
    deliver(payload_plan: :startups, current_plan: :startups, previous: { plan: prices[:hacker] })

    expect(account.custom_attributes['plan_name']).to eq('Startups')
    expect(account.limits['captain_responses']).to eq(300)
  end

  it 'skips a slow subscription read once a read that started later has been applied' do
    reads = 0
    allow(Stripe::Subscription).to receive(:retrieve) do
      reads += 1
      next Stripe::Subscription.construct_from(subscription_on(:business)) if reads == 2

      # While this read is still in flight, a later delivery reads Business and applies it
      described_class.new.perform(event: updated_event(:business, previous: { plan: prices[:startups] }))
      Stripe::Subscription.construct_from(subscription_on(:startups))
    end

    described_class.new.perform(event: updated_event(:startups, previous: { plan: prices[:hacker] }))

    expect(account.reload.custom_attributes['plan_name']).to eq('Business')
    expect(account.limits['captain_responses']).to eq(500)
  end

  it 'orders reads by the database clock, so a host clock running ahead cannot block a newer read' do
    travel_to(1.hour.from_now) do
      deliver(payload_plan: :startups, current_plan: :startups, previous: { plan: prices[:hacker] })
    end
    deliver(payload_plan: :business, current_plan: :business, previous: { plan: prices[:startups] })

    expect(account.custom_attributes['plan_name']).to eq('Business')
    expect(account.limits['captain_responses']).to eq(500)
  end

  it 'settles the plan change once a retry succeeds after a failed delivery' do
    reconcile = Enterprise::Billing::ReconcilePlanFeaturesService
    allow(reconcile).to receive(:new).and_raise(ActiveRecord::RecordInvalid)

    expect do
      deliver(payload_plan: :startups, current_plan: :startups, previous: { plan: prices[:hacker] })
    end.to raise_error(ActiveRecord::RecordInvalid)
    expect(account.reload.custom_attributes['plan_name']).to eq('Hacker')

    allow(reconcile).to receive(:new).and_call_original
    deliver(payload_plan: :startups, current_plan: :startups, previous: { plan: prices[:hacker] })

    expect(account.custom_attributes['plan_name']).to eq('Startups')
    expect(account.limits['captain_responses']).to eq(300)
  end

  it 'renews against the old plan when an older event arrives before the renewal onto a new plan' do
    account.update!(
      custom_attributes: account.custom_attributes.merge(
        'plan_name' => 'Business', 'captain_responses_usage' => 450, 'subscription_ends_on' => Time.zone.at(period_end)
      ),
      limits: { 'captain_responses' => 500 }
    )

    deliver(payload_plan: :business, current_plan: :startups, previous: { default_payment_method: nil },
            current_period_end: next_period_end)
    deliver(payload_plan: :startups, current_plan: :startups, previous: { plan: prices[:business], current_period_start: 1 },
            payload_period_end: next_period_end, current_period_end: next_period_end)

    expect(account.custom_attributes).to include('plan_name' => 'Startups', 'captain_responses_usage' => 0)
    expect(account.limits['captain_responses']).to eq(300)
  end
end
