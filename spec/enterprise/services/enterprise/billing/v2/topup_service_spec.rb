require 'rails_helper'

describe Enterprise::Billing::V2::TopupService do
  let(:account) { create(:account, custom_attributes: { 'stripe_customer_id' => 'cus_123', 'plan_name' => 'Business' }) }
  let(:service) { described_class.new(account: account) }

  before do
    allow(Enterprise::Billing::V2::TopupCatalog).to receive(:find_option).with(500).and_return(
      credits: 500,
      amount: 50.0,
      currency: 'usd'
    )
    allow(Stripe::Customer).to receive(:retrieve).and_return(
      OpenStruct.new(invoice_settings: OpenStruct.new(default_payment_method: 'pm_123'), default_source: nil)
    )
    allow(Stripe::Invoice).to receive(:create).and_return(Stripe::Invoice.construct_from(id: 'in_123'))
    allow(Stripe::InvoiceItem).to receive(:create)
    allow(Stripe::Invoice).to receive(:finalize_invoice).and_return(
      Stripe::Invoice.construct_from(id: 'in_123', status: 'open')
    )
    allow(Stripe::Invoice).to receive(:pay).and_return(
      Stripe::Invoice.construct_from(id: 'in_123', status: 'paid', total: 5000, hosted_invoice_url: 'https://invoice.stripe.com')
    )
    allow(Stripe::Billing::CreditGrant).to receive(:create).and_return({ 'id' => 'credgr_123' })
  end

  describe '#create_topup' do
    context 'when customer has a default payment method' do
      it 'creates topup successfully' do
        result = service.create_topup(credits: 500)

        expect(result[:success]).to be true
        expect(result[:credits]).to eq(500)
        expect(result[:amount]).to eq(50.0)
      end
    end

    context 'when customer has no default payment method but has payment methods available' do
      let(:payment_methods_list) { OpenStruct.new(data: [OpenStruct.new(id: 'pm_first')]) }

      before do
        allow(Stripe::Customer).to receive(:retrieve).and_return(
          OpenStruct.new(
            id: 'cus_123',
            invoice_settings: OpenStruct.new(default_payment_method: nil),
            default_source: nil
          )
        )
        allow(Stripe::PaymentMethod).to receive(:list).and_return(payment_methods_list)
        allow(Stripe::Customer).to receive(:update)
      end

      it 'automatically sets default payment method and creates topup' do
        result = service.create_topup(credits: 500)

        expect(Stripe::Customer).to have_received(:update).with(
          'cus_123',
          invoice_settings: { default_payment_method: 'pm_first' }
        )
        expect(result[:success]).to be true
        expect(result[:credits]).to eq(500)
      end
    end

    context 'when customer has no payment methods at all' do
      let(:empty_payment_methods) { OpenStruct.new(data: []) }

      before do
        allow(Stripe::Customer).to receive(:retrieve).and_return(
          OpenStruct.new(
            id: 'cus_123',
            invoice_settings: OpenStruct.new(default_payment_method: nil),
            default_source: nil
          )
        )
        allow(Stripe::PaymentMethod).to receive(:list).and_return(empty_payment_methods)
      end

      it 'returns an error' do
        result = service.create_topup(credits: 500)

        expect(result[:success]).to be false
        expect(result[:message]).to include('No payment methods found')
      end
    end

    context 'when on Hacker plan' do
      let(:account) { create(:account, custom_attributes: { 'stripe_customer_id' => 'cus_123', 'plan_name' => 'Hacker' }) }

      it 'returns an error' do
        result = service.create_topup(credits: 500)

        expect(result[:success]).to be false
        expect(result[:message]).to include('only available for Startup, Business, and Enterprise plans')
      end
    end

    context 'when no plan is set' do
      let(:account) { create(:account, custom_attributes: { 'stripe_customer_id' => 'cus_123' }) }

      it 'returns an error' do
        result = service.create_topup(credits: 500)

        expect(result[:success]).to be false
        expect(result[:message]).to include('only available for Startup, Business, and Enterprise plans')
      end
    end

    context 'with invalid topup amount' do
      it 'returns an error for zero credits' do
        result = service.create_topup(credits: 0)

        expect(result[:success]).to be false
        expect(result[:message]).to eq('Invalid topup amount')
      end

      it 'returns an error for negative credits' do
        result = service.create_topup(credits: -100)

        expect(result[:success]).to be false
        expect(result[:message]).to eq('Invalid topup amount')
      end
    end

    context 'when topup amount is not supported' do
      before do
        allow(Enterprise::Billing::V2::TopupCatalog).to receive(:find_option).with(999).and_return(nil)
      end

      it 'returns an error' do
        result = service.create_topup(credits: 999)

        expect(result[:success]).to be false
        expect(result[:message]).to eq('Unsupported topup amount')
      end
    end
  end
end
