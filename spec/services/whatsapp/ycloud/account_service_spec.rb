require 'rails_helper'

describe Whatsapp::Ycloud::AccountService do
  let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'ycloud', sync_templates: false, validate_provider_config: false) }
  let(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }
  let(:api_base) { 'https://api.ycloud.com/v2' }
  let(:headers) { { 'Content-Type' => 'application/json' } }

  describe '#get_balance' do
    it 'retrieves account balance' do
      stub = stub_request(:get, "#{api_base}/balance")
        .to_return(status: 200, body: { amount: 150.50, currency: 'USD' }.to_json, headers: headers)

      response = service.get_balance
      expect(stub).to have_been_requested
      expect(response.parsed_response['amount']).to eq(150.50)
      expect(response.parsed_response['currency']).to eq('USD')
    end
  end

  describe '#list_business_accounts' do
    it 'lists WABAs' do
      stub = stub_request(:get, "#{api_base}/whatsapp/businessAccounts?page=1&limit=20")
        .to_return(status: 200, body: { items: [{ id: 'waba_001' }], total: 1 }.to_json, headers: headers)

      response = service.list_business_accounts
      expect(stub).to have_been_requested
      expect(response.parsed_response['items'].first['id']).to eq('waba_001')
    end
  end

  describe '#get_business_account' do
    it 'retrieves a specific WABA' do
      stub = stub_request(:get, "#{api_base}/whatsapp/businessAccounts/waba_001")
        .to_return(status: 200, body: { id: 'waba_001', name: 'Test Business' }.to_json, headers: headers)

      response = service.get_business_account('waba_001')
      expect(stub).to have_been_requested
      expect(response.parsed_response['name']).to eq('Test Business')
    end
  end
end
