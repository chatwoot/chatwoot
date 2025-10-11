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
        account.update!(
          custom_attributes: {
            'stripe_billing_version' => 2,
            'monthly_credits' => 100,
            'topup_credits' => 50
          }
        )

        account.credit_transactions.create!(
          transaction_type: 'use',
          credit_type: 'monthly',
          amount: 5,
          description: 'spec monthly',
          metadata: { 'feature' => 'ai_captain' },
          created_at: Time.current
        )

        account.credit_transactions.create!(
          transaction_type: 'use',
          credit_type: 'topup',
          amount: 3,
          description: 'spec topup',
          metadata: { 'feature' => 'ai_summary' },
          created_at: Time.current
        )
      end

      it 'aggregates usage from credit transactions' do
        result = service.fetch_usage_summary

        expect(result[:success]).to be(true)
        expect(result[:total_usage]).to eq(8)
        expect(result[:credits_remaining]).to eq(150)
        expect(result[:usage_by_feature]).to include('ai_captain' => 5, 'ai_summary' => 3)
      end
    end
  end

  describe '#recent_transactions' do
    it 'returns recent transactions' do
      account.update!(custom_attributes: { 'stripe_billing_version' => 2 })

      3.times do |i|
        account.credit_transactions.create!(
          transaction_type: 'use',
          amount: i + 1,
          credit_type: 'monthly',
          created_at: i.hours.ago
        )
      end

      transactions = service.recent_transactions(limit: 2)

      expect(transactions.count).to eq(2)
      expect(transactions.first.amount).to eq(1) # Most recent
    end
  end
end
