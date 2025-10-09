require 'rails_helper'

describe Enterprise::Billing::V2::UsageReporterService do
  let(:account) { create(:account) }
  let(:service) { described_class.new(account: account) }
  let(:config) { Rails.application.config.stripe_v2 }
  let!(:original_config) { config.deep_dup }

  before do
    account.update!(
      custom_attributes: (account.custom_attributes || {}).merge(
        'stripe_billing_version' => 2,
        'stripe_customer_id' => 'cus_test_123'
      )
    )

    config[:meter_id] = 'mtr_test_123'
    config[:meter_event_name] = 'chat_prompts'
  end

  after { config.replace(original_config) }

  it 'posts usage events to Stripe meters' do # rubocop:disable RSpec/MultipleExpectations
    response = { 'id' => 'me_test_123' }
    stripe_client = instance_double(Stripe::StripeClient)
    allow(service).to receive(:stripe_client).and_return(stripe_client)
    allow(stripe_client).to receive(:execute_request).and_return(response)

    result = service.report(5, 'ai_test')

    expect(result).to include(success: true, reported_credits: 5)
    expect(stripe_client).to have_received(:execute_request) do |method, path, **kw|
      expect(method).to eq(:post)
      expect(path).to eq('/v1/billing/meter_events')
      expect(kw[:headers]).to include('Idempotency-Key')
      expect(kw[:params][:event_name]).to eq('chat_prompts')
      expect(kw[:params][:payload][:value]).to eq(5)
      expect(kw[:params][:payload][:stripe_customer_id]).to eq('cus_test_123')
    end
  end
end
