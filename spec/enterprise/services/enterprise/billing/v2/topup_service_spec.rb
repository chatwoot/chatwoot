require 'rails_helper'
require 'ostruct'

describe Enterprise::Billing::V2::TopupService do
  let(:account) { create(:account, custom_attributes: { 'stripe_customer_id' => 'cus_123' }) }
  let(:service) { described_class.new(account: account) }
  let(:invoice) { Stripe::Invoice.construct_from(id: 'in_123', customer: 'cus_123', currency: 'usd') }
  let(:invoice_item) do
    Stripe::InvoiceItem.construct_from(
      id: 'ii_123',
      invoice: 'in_123',
      amount: 5000,
      currency: 'usd'
    )
  end
  let(:finalized_invoice) { Stripe::Invoice.construct_from(id: 'in_123', status: 'open') }
  let(:paid_invoice) { Stripe::Invoice.construct_from(id: 'in_123', status: 'paid') }
  let(:credit_grant) do
    {
      'id' => 'credgr_123',
      'customer' => 'cus_123',
      'amount' => { 'type' => 'monetary', 'monetary' => { 'value' => 5000, 'currency' => 'usd' } }
    }
  end

  before do
    allow(Enterprise::Billing::V2::TopupCatalog).to receive(:find_option).with(500).and_return(
      credits: 500,
      amount: 50.0,
      currency: 'usd'
    )

    # Mock Stripe Invoice creation
    allow(Stripe::Invoice).to receive(:create).and_return(invoice)

    # Mock Stripe InvoiceItem creation
    allow(Stripe::InvoiceItem).to receive(:create).and_return(invoice_item)

    # Mock Stripe Invoice finalization
    allow(Stripe::Invoice).to receive(:finalize_invoice).and_return(finalized_invoice)

    # Mock Stripe Invoice payment
    allow(Stripe::Invoice).to receive(:pay).and_return(paid_invoice)

    # Mock Stripe Credit Grant creation (monetary amount)
    allow(Stripe::Billing::CreditGrant).to receive(:create).and_return(credit_grant)
  end

  describe '#create_topup' do
    context 'when successful' do
      before do
        service.create_topup(credits: 500)
      end

      it 'creates invoice with correct parameters' do
        expect(Stripe::Invoice).to have_received(:create).with(
          hash_including(
            customer: 'cus_123',
            currency: 'usd',
            collection_method: 'charge_automatically'
          ),
          hash_including(:api_key)
        )
      end

      it 'creates invoice item with topup amount' do
        expect(Stripe::InvoiceItem).to have_received(:create).with(
          hash_including(
            customer: 'cus_123',
            amount: 5000,
            currency: 'usd',
            invoice: 'in_123',
            description: 'Credit Topup: 500 credits'
          ),
          hash_including(:api_key)
        )
      end

      it 'finalizes invoice for payment' do
        expect(Stripe::Invoice).to have_received(:finalize_invoice).with(
          'in_123',
          hash_including(auto_advance: false),
          hash_including(:api_key)
        )
      end

      it 'pays the invoice explicitly' do
        expect(Stripe::Invoice).to have_received(:pay).with(
          'in_123',
          {},
          hash_including(:api_key)
        )
      end

      it 'creates credit grant with monetary amount' do
        expect(Stripe::Billing::CreditGrant).to have_received(:create).with(
          hash_including(
            customer: 'cus_123',
            name: 'Topup: 500 credits',
            amount: hash_including(
              type: 'monetary',
              monetary: hash_including(currency: 'usd', value: 5000)
            ),
            applicability_config: hash_including(scope: hash_including(price_type: 'metered')),
            category: 'paid',
            metadata: hash_including(
              account_id: account.id.to_s,
              source: 'topup',
              credits: '500'
            )
          ),
          hash_including(:api_key)
        )
      end

      it 'returns success response with all ids' do
        result = service.create_topup(credits: 500)

        expect(result[:success]).to be true
        expect(result[:credits]).to eq(500)
        expect(result[:invoice_id]).to eq('in_123')
        expect(result[:credit_grant_id]).to eq('credgr_123')
      end
    end

    it 'returns error when option missing' do
      allow(Enterprise::Billing::V2::TopupCatalog).to receive(:find_option).and_return(nil)

      result = service.create_topup(credits: 999)

      expect(result[:success]).to be false
      expect(result[:message]).to eq('Unsupported topup amount')
    end
  end
end
