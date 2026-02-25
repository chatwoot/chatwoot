require 'rails_helper'

describe Enterprise::Billing::TopupFulfillmentService do
  subject(:service) { described_class.new(account: account) }

  let(:account) { create(:account) }
  let(:stripe_customer_id) { 'cus_test123' }

  before do
    account.update!(
      custom_attributes: { stripe_customer_id: stripe_customer_id },
      limits: { 'captain_responses' => 1000 }
    )
    allow(Stripe::Billing::CreditGrant).to receive(:create)
  end

  describe '#fulfill' do
    it 'adds credits to account limits' do
      service.fulfill(credits: 1000, amount_cents: 2000, currency: 'usd')

      expect(account.reload.limits['captain_responses']).to eq(2000)
    end

    it 'creates a Stripe credit grant' do
      service.fulfill(credits: 1000, amount_cents: 2000, currency: 'usd')

      expect(Stripe::Billing::CreditGrant).to have_received(:create).with(
        hash_including(
          customer: stripe_customer_id,
          name: 'Topup: 1000 credits',
          category: 'paid'
        )
      )
    end
  end
end
