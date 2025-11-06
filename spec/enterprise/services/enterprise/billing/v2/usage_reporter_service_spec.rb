require 'rails_helper'

describe Enterprise::Billing::V2::UsageReporterService do
  let(:account) { create(:account, custom_attributes: { 'stripe_billing_version' => 2, 'stripe_customer_id' => 'cus_123' }) }
  let(:service) { described_class.new(account: account) }

  describe '#report' do
    it 'posts usage to Stripe' do
      allow(Stripe::Billing::MeterEvent).to receive(:create).and_return(OpenStruct.new(identifier: 'me_123'))

      result = service.report(5, 'ai_test')

      expect(result[:success]).to be true
      expect(result[:event_id]).to eq('me_123')
      expect(Stripe::Billing::MeterEvent).to have_received(:create)
    end
  end
end
