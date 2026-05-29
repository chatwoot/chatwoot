require 'rails_helper'

RSpec.describe Enterprise::Billing::TrackPaymentAttributionService do
  subject(:service) { described_class.new(account: account, invoice: invoice) }

  let(:account) do
    create(
      :account,
      custom_attributes: {
        'stripe_customer_id' => 'cus_123',
        'billing_attribution' => {
          'datafast_visitor_id' => 'visitor-123'
        }
      }
    )
  end
  let!(:admin) { create(:user, account: account, role: :administrator, email: 'admin@example.com') }
  let(:invoice) do
    {
      'id' => 'in_123',
      'amount_paid' => 2900,
      'currency' => 'usd',
      'customer' => 'cus_123',
      'customer_name' => 'Acme Finance',
      'billing_reason' => 'subscription_create'
    }
  end

  before do
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
    allow(HTTParty).to receive(:post).and_return(instance_double(HTTParty::Response, success?: true))
    allow(GlobalConfigService).to receive(:load).with('DATAFAST_API_KEY', nil).and_return('test-key')
  end

  it 'sends payment attribution to the payment API' do
    service.perform

    expect(HTTParty).to have_received(:post).with(
      'https://datafa.st/api/v1/payments',
      headers: {
        'Authorization' => 'Bearer test-key',
        'Content-Type' => 'application/json'
      },
      body: {
        amount: 29.0,
        currency: 'USD',
        transaction_id: 'in_123',
        datafast_visitor_id: 'visitor-123',
        email: admin.email,
        name: 'Acme Finance',
        customer_id: 'cus_123',
        renewal: false
      }.to_json,
      timeout: 5
    )
  end

  it 'skips the API call when attribution is unavailable' do
    account.update!(custom_attributes: { 'stripe_customer_id' => 'cus_123' })

    service.perform

    expect(HTTParty).not_to have_received(:post)
  end

  it 'skips the API call when the installation config is unavailable' do
    allow(GlobalConfigService).to receive(:load).with('DATAFAST_API_KEY', nil).and_return(nil)

    service.perform

    expect(HTTParty).not_to have_received(:post)
  end
end
