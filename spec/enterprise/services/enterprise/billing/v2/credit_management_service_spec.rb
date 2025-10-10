require 'rails_helper'

describe Enterprise::Billing::V2::CreditManagementService do
  let(:account) { create(:account) }
  let(:service) { described_class.new(account: account) }

  before do
    allow(Enterprise::Billing::ReportUsageJob).to receive(:perform_later)
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('STRIPE_V2_METER_EVENT_NAME', anything).and_return('ai_prompts')
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('STRIPE_V2_METER_EVENT_NAME').and_return('ai_prompts')
    allow(ENV).to receive(:[]).with('STRIPE_V2_METER_ID').and_return(nil) # Disable Stripe meter fetching

    # Stub Stripe credit grant creation
    allow(Stripe::Billing::CreditGrant).to receive(:create).and_return(
      OpenStruct.new(id: 'cg_test_123')
    )

    account.update!(
      custom_attributes: (account.custom_attributes || {}).merge(
        'stripe_billing_version' => 2,
        'monthly_credits' => 100,
        'topup_credits' => 50,
        'stripe_customer_id' => 'cus_test_123'
      )
    )
  end

  describe '#credit_balance' do
    it 'returns current credit balance' do
      balance = service.credit_balance

      expect(balance[:monthly]).to eq(100)
      expect(balance[:topup]).to eq(50)
      expect(balance[:total]).to eq(150)
    end
  end

  describe '#use_credit' do
    before do
      # Stub the Stripe meter event creation
      allow(Stripe::Billing::MeterEvent).to receive(:create).and_return(
        OpenStruct.new(identifier: 'test_event_123')
      )
    end

    context 'when sufficient monthly credits' do
      it 'uses monthly credits first' do
        result = service.use_credit(feature: 'ai_test', amount: 10)

        expect(result[:success]).to be(true)
        expect(result[:credits_used]).to eq(10)

        account.reload
        expect(account.custom_attributes['monthly_credits']).to eq(90)
        expect(account.custom_attributes['topup_credits']).to eq(50)
        expect(account.credit_transactions.order(created_at: :desc).first.metadata['feature']).to eq('ai_test')
      end
    end

    context 'when insufficient credits' do
      it 'returns error' do
        result = service.use_credit(feature: 'ai_test', amount: 200)

        expect(result[:success]).to be(false)
        expect(result[:message]).to eq('Insufficient credits')
      end
    end
  end

  describe '#grant_monthly_credits' do
    it 'grants new monthly credits and logs transaction metadata' do
      expect { service.grant_monthly_credits(500, metadata: { source: 'spec' }) }
        .to change { account.credit_transactions.count }.by(2) # expire + grant

      account.reload
      expect(account.custom_attributes['monthly_credits']).to eq(500)
      expect(account.credit_transactions.order(created_at: :desc).first.metadata['source']).to eq('spec')
    end
  end

  describe '#add_topup_credits' do
    it 'adds topup credits' do
      expect { service.add_topup_credits(100, metadata: { source: 'spec' }) }
        .to change { account.credit_transactions.count }.by(1)

      account.reload
      expect(account.custom_attributes['topup_credits']).to eq(150)
      expect(account.credit_transactions.order(created_at: :desc).first.metadata['source']).to eq('spec')
    end
  end
end
