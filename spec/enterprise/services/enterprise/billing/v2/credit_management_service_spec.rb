require 'rails_helper'

describe Enterprise::Billing::V2::CreditManagementService do
  let(:account) { create(:account) }
  let(:service) { described_class.new(account: account) }

  before do
    account.update!(
      custom_attributes: {
        'stripe_billing_version' => 2,
        'monthly_credits' => 100,
        'topup_credits' => 50,
        'stripe_customer_id' => 'cus_test_123',
        'stripe_meter_event_name' => 'ai_prompts'
      }
    )

    # Stub Stripe meter event creation
    allow(Stripe::Billing::MeterEvent).to receive(:create).and_return(
      OpenStruct.new(identifier: 'test_event_123')
    )
  end

  describe '#total_credits' do
    it 'returns sum of monthly and topup credits' do
      expect(service.total_credits).to eq(150)
    end
  end

  describe '#use_credit' do
    context 'when sufficient credits' do
      it 'uses credits and reports to Stripe' do
        result = service.use_credit(feature: 'ai_test', amount: 10)

        expect(result[:success]).to be(true)
        expect(result[:credits_used]).to eq(10)
        expect(result[:remaining]).to eq(140)

        account.reload
        expect(account.custom_attributes['monthly_credits']).to eq(90)
        expect(account.custom_attributes['topup_credits']).to eq(50)
      end
    end

    context 'when insufficient credits' do
      it 'returns error' do
        result = service.use_credit(feature: 'ai_test', amount: 200)

        expect(result[:success]).to be(false)
        expect(result[:message]).to eq('Insufficient credits')
      end
    end

    context 'when using mixed credits' do
      it 'uses monthly first then topup' do
        result = service.use_credit(feature: 'ai_test', amount: 120)

        expect(result[:success]).to be(true)
        account.reload
        expect(account.custom_attributes['monthly_credits']).to eq(0)
        expect(account.custom_attributes['topup_credits']).to eq(30)
      end
    end
  end

  describe '#sync_monthly_credits' do
    it 'updates monthly credits from Stripe' do
      service.sync_monthly_credits(500)

      account.reload
      expect(account.custom_attributes['monthly_credits']).to eq(500)
      expect(account.credit_transactions.last.description).to eq('Monthly credits from Stripe')
    end
  end

  describe '#sync_monthly_expired' do
    it 'expires monthly credits' do
      expired = service.sync_monthly_expired

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
      expect(account.credit_transactions.last.description).to eq('Topup credits added')
    end
  end
end
