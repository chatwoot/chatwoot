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

  it 'posts usage events to Stripe meters' do
    meter_event = OpenStruct.new(identifier: 'me_test_123')
    allow(Stripe::Billing::MeterEvent).to receive(:create).and_return(meter_event)

    # Stub ENV to return the configured meter event name from config
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('STRIPE_V2_METER_EVENT_NAME').and_return(nil)

    result = service.report(5, 'ai_test')

    expect(result).to include(success: true, reported_credits: 5)
    expect(Stripe::Billing::MeterEvent).to have_received(:create) do |params, options|
      expect(params[:event_name]).to eq('chat_prompts') # Should use the config value
      expect(params[:payload][:value]).to eq('5')
      expect(params[:payload][:stripe_customer_id]).to eq('cus_test_123')
      expect(options[:stripe_version]).to eq('2025-08-27.preview')
    end
  end
end
