require 'rails_helper'

describe Enterprise::Billing::V2::CreditManagementService do
  let(:account) { create(:account) }
  let(:service) { described_class.new(account: account) }

  before do
    account.update!(
      custom_attributes: {
        'stripe_billing_version' => 2,
        'stripe_customer_id' => 'cus_test_123',
        'stripe_meter_event_name' => 'ai_prompts',
        'monthly_credits' => 100,
        'topup_credits' => 50
      }
    )
  end

  describe '#total_credits' do
    it 'returns sum of monthly and topup credits' do
      expect(service.total_credits).to eq(150)
    end
  end

  describe '#sync_monthly_credits' do
    it 'updates monthly credits' do
      service.sync_monthly_credits(500)

      account.reload
      expect(account.custom_attributes['monthly_credits']).to eq(500)
    end
  end

  describe '#expire_monthly_credits' do
    it 'expires monthly credits' do
      expired = service.expire_monthly_credits

      expect(expired).to eq(100)
      account.reload
      expect(account.custom_attributes['monthly_credits']).to eq(0)
    end
  end

  describe '#add_topup_credits' do
    it 'adds topup credits' do
      service.add_topup_credits(100)

      account.reload
      expect(account.custom_attributes['topup_credits']).to eq(150)
    end
  end
end
