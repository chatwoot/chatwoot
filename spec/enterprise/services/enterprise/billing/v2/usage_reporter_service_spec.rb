require 'rails_helper'

describe Enterprise::Billing::V2::UsageReporterService do
  let(:account) { create(:account) }
  let(:service) { described_class.new(account: account) }

  before do
    account.update!(
      custom_attributes: {
        'stripe_billing_version' => 2,
        'stripe_customer_id' => 'cus_test_123',
        'stripe_meter_event_name' => 'ai_prompts'
      }
    )
  end

  it 'posts usage events to Stripe meters' do
    meter_event = OpenStruct.new(identifier: 'me_test_123')
    allow(Stripe::Billing::MeterEvent).to receive(:create).and_return(meter_event)

    result = service.report(5, 'ai_test')

    expect(result).to include(success: true, event_id: 'me_test_123')
    expect(Stripe::Billing::MeterEvent).to have_received(:create) do |params, options|
      expect(params[:event_name]).to eq('ai_prompts')
      expect(params[:payload][:value]).to eq('5')
      expect(params[:payload][:stripe_customer_id]).to eq('cus_test_123')
      expect(options[:stripe_version]).to eq('2025-08-27.preview')
    end
  end

  context 'when V2 billing not enabled' do
    before do
      account.update!(custom_attributes: { 'stripe_billing_version' => 1 })
    end

    it 'returns error' do
      result = service.report(5, 'ai_test')

      expect(result).to include(success: false, message: 'V2 billing not enabled')
    end
  end

  context 'when no Stripe customer' do
    before do
      account.update!(custom_attributes: { 'stripe_billing_version' => 2 })
    end

    it 'returns error' do
      result = service.report(5, 'ai_test')

      expect(result).to include(success: false, message: 'No Stripe customer')
    end
  end
end
