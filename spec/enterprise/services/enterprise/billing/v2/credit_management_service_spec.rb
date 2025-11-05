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
        'captain_responses_monthly' => 100,
        'captain_responses_topup' => 50,
        'captain_responses_usage' => 0,
        'captain_documents_usage' => 0
      },
      limits: {
        'captain_responses' => 150,
        'captain_documents' => 200
      }
    )
  end

  describe '#sync_monthly_response_credits' do
    it 'updates monthly credits and syncs total' do
      service.sync_monthly_response_credits(500)

      account.reload
      expect(account.custom_attributes['captain_responses_monthly']).to eq(500)
      expect(account.limits['captain_responses']).to eq(550) # 500 + 50 topup (stored in limits ONLY)
    end

    it 'preserves topup credits capped at remaining balance' do
      # Set usage to 80
      account.update!(custom_attributes: account.custom_attributes.merge('captain_responses_usage' => 80))

      service.sync_monthly_response_credits(100)

      account.reload
      # Current: monthly=100, topup=50, total=150, usage=80
      # Remaining: 150 - 80 = 70
      # Topup should be capped at min(50, 70) = 50
      expect(account.custom_attributes['captain_responses_topup']).to eq(50)
      expect(account.limits['captain_responses']).to eq(150)
    end

    it 'caps topup when usage exceeds new monthly allocation' do
      # Usage is 120, new monthly is 100, topup is 50
      account.update!(custom_attributes: account.custom_attributes.merge('captain_responses_usage' => 120))

      service.sync_monthly_response_credits(100)

      account.reload
      # New total would be: monthly=100 + topup=50 = 150
      # Usage: 120
      # Remaining: 150 - 120 = 30
      # Topup should be capped at min(50, 30) = 30
      expect(account.custom_attributes['captain_responses_topup']).to eq(30)
      expect(account.limits['captain_responses']).to eq(130) # 100 + 30
    end

    it 'zeros topup when usage exceeds new total' do
      # Usage is 160, new monthly is 100, topup is 50
      account.update!(custom_attributes: account.custom_attributes.merge('captain_responses_usage' => 160))

      service.sync_monthly_response_credits(100)

      account.reload
      # New total would be: monthly=100 + topup=50 = 150
      # Usage: 160 (exceeds total)
      # Remaining: max(0, 150 - 160) = 0
      # Topup should be: min(50, 0) = 0
      expect(account.custom_attributes['captain_responses_topup']).to eq(0)
      expect(account.limits['captain_responses']).to eq(100) # 100 + 0
    end
  end

  describe '#sync_document_credits' do
    it 'updates document credits total' do
      service.sync_document_credits(500)

      account.reload
      expect(account.limits['captain_documents']).to eq(500) # Stored in limits hash ONLY
    end
  end

  describe '#expire_monthly_response_credits' do
    it 'expires monthly credits and preserves topup' do
      expired = service.expire_monthly_response_credits

      expect(expired).to eq(100)
      account.reload
      expect(account.custom_attributes['captain_responses_monthly']).to eq(0)
      expect(account.custom_attributes['captain_responses_topup']).to eq(50)
      expect(account.limits['captain_responses']).to eq(50)
    end
  end

  describe '#add_response_topup_credits' do
    it 'adds topup credits and updates total' do
      service.add_response_topup_credits(100)

      account.reload
      expect(account.custom_attributes['captain_responses_topup']).to eq(150) # 50 + 100
      expect(account.limits['captain_responses']).to eq(250) # 100 monthly + 150 topup
    end
  end
end
