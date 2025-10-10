require 'rails_helper'

describe Enterprise::Billing::V2::UsageAnalyticsService do
  let(:account) { create(:account) }
  let(:service) { described_class.new(account: account) }

  describe '#fetch_usage_summary' do
    context 'when account not on v2 billing' do
      it 'returns error response' do
        result = service.fetch_usage_summary

        expect(result[:success]).to be(false)
        expect(result[:message]).to eq('Not on V2 billing')
      end
    end

    context 'when account has usage' do
      before do
        account.update!(custom_attributes: (account.custom_attributes || {}).merge(
          'stripe_billing_version' => 2,
          'stripe_customer_id' => 'cus_123'
        ))

        account.credit_transactions.create!(
          transaction_type: 'use',
          credit_type: 'monthly',
          amount: 5,
          description: 'spec monthly',
          metadata: {},
          created_at: Time.current
        )

        account.credit_transactions.create!(
          transaction_type: 'use',
          credit_type: 'topup',
          amount: 3,
          description: 'spec topup',
          metadata: {},
          created_at: Time.current
        )

        # Stub the Stripe API call to return nil (which will fallback to local data)
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('STRIPE_V2_METER_ID').and_return(nil)
      end

      it 'aggregates usage from credit transactions' do
        result = service.fetch_usage_summary

        expect(result[:success]).to be(true)
        expect(result[:total_usage]).to eq(8)
        expect(result[:source]).to eq('local')
      end
    end
  end
end
