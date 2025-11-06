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
    it 'creates topup' do
      result = service.create_topup(credits: 500)

      expect(result[:success]).to be true
      expect(result[:credits]).to eq(500)
    end
  end
end
