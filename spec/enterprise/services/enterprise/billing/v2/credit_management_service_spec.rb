require 'rails_helper'

describe Enterprise::Billing::V2::CreditManagementService do
  let(:account) { create(:account) }
  let(:service) { described_class.new(account: account) }

  before do
    account.update!(
      custom_attributes: { 'captain_responses_usage' => 0 },
      limits: { 'captain_responses_monthly' => 100, 'captain_responses_topup' => 50 }
    )
  end

  describe '#sync_monthly_response_credits' do
    it 'updates monthly credits' do
      service.sync_monthly_response_credits(500)

      expect(account.reload.limits['captain_responses_monthly']).to eq(500)
      expect(account.limits['captain_responses']).to eq(550)
    end
  end

  describe '#add_response_topup_credits' do
    it 'adds topup credits' do
      service.add_response_topup_credits(100)

      expect(account.reload.limits['captain_responses_topup']).to eq(150)
      expect(account.limits['captain_responses']).to eq(250)
    end
  end
end
