require 'rails_helper'

describe Enterprise::Billing::TopupCheckoutService do
  subject(:service) { described_class.new(account: account) }

  let(:account) { create(:account) }
  let(:stripe_customer_id) { 'cus_test123' }
  let(:invoice_settings) { Struct.new(:default_payment_method).new('pm_test') }
  let(:stripe_customer) { Struct.new(:invoice_settings, :default_source).new(invoice_settings, nil) }
  let(:stripe_invoice) { Struct.new(:id).new('inv_test123') }

  before do
    create(:installation_config, name: 'CHATWOOT_CLOUD_PLANS', value: [
             { 'name' => 'Hacker', 'product_id' => ['prod_hacker'], 'price_ids' => ['price_hacker'] },
             { 'name' => 'Business', 'product_id' => ['prod_business'], 'price_ids' => ['price_business'] }
           ])

    account.update!(
      custom_attributes: { plan_name: 'Business', stripe_customer_id: stripe_customer_id },
      limits: { 'captain_responses' => 500 }
    )

    allow(Stripe::Customer).to receive(:retrieve).and_return(stripe_customer)
    allow(Stripe::Invoice).to receive(:create).and_return(stripe_invoice)
    allow(Stripe::InvoiceItem).to receive(:create)
    allow(Stripe::Invoice).to receive(:finalize_invoice)
    allow(Stripe::Invoice).to receive(:pay)
    allow(Stripe::Billing::CreditGrant).to receive(:create)
  end

  describe '#create_checkout_session' do
    it 'successfully processes topup and returns correct response' do
      result = service.create_checkout_session(credits: 1000)

      expect(result[:credits]).to eq(1000)
      expect(result[:amount]).to eq(20.0)
      expect(result[:currency]).to eq('usd')
    end

    it 'updates account limits after successful topup' do
      service.create_checkout_session(credits: 1000)

      expect(account.reload.limits['captain_responses']).to eq(1500)
    end

    it 'raises error for invalid credits' do
      expect do
        service.create_checkout_session(credits: 500)
      end.to raise_error(Enterprise::Billing::TopupCheckoutService::Error)
    end

    it 'raises error when account is on free plan' do
      account.update!(custom_attributes: { plan_name: 'Hacker', stripe_customer_id: stripe_customer_id })

      expect do
        service.create_checkout_session(credits: 1000)
      end.to raise_error(Enterprise::Billing::TopupCheckoutService::Error)
    end
  end
end
