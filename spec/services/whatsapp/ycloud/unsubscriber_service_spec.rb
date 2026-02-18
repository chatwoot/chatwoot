require 'rails_helper'

describe Whatsapp::Ycloud::UnsubscriberService do
  let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'ycloud', sync_templates: false, validate_provider_config: false) }
  let(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }
  let(:api_base) { 'https://api.ycloud.com/v2' }
  let(:headers) { { 'Content-Type' => 'application/json' } }

  describe '#create' do
    it 'adds an unsubscriber' do
      stub = stub_request(:post, "#{api_base}/unsubscribers")
        .with(body: hash_including({ 'customer' => '+1234567890', 'channel' => 'whatsapp' }))
        .to_return(status: 200, body: { customer: '+1234567890', channel: 'whatsapp' }.to_json, headers: headers)

      service.create(customer: '+1234567890', channel: 'whatsapp')
      expect(stub).to have_been_requested
    end
  end

  describe '#list' do
    it 'lists unsubscribers' do
      stub = stub_request(:get, "#{api_base}/unsubscribers?page=1&limit=20")
        .to_return(status: 200, body: { items: [], total: 0 }.to_json, headers: headers)

      service.list
      expect(stub).to have_been_requested
    end
  end

  describe '#check' do
    it 'returns true when customer is unsubscribed' do
      stub_request(:get, "#{api_base}/unsubscribers/+1234567890/whatsapp")
        .to_return(status: 200, body: { customer: '+1234567890' }.to_json, headers: headers)

      expect(service.check('+1234567890', 'whatsapp')).to be true
    end

    it 'returns false when customer is not unsubscribed' do
      stub_request(:get, "#{api_base}/unsubscribers/+1234567890/whatsapp")
        .to_return(status: 404, body: '{}', headers: headers)

      expect(service.check('+1234567890', 'whatsapp')).to be false
    end
  end

  describe '#delete' do
    it 'removes an unsubscriber' do
      stub = stub_request(:delete, "#{api_base}/unsubscribers/+1234567890/whatsapp")
        .to_return(status: 200, body: '{}', headers: headers)

      service.delete('+1234567890', 'whatsapp')
      expect(stub).to have_been_requested
    end
  end

  describe '#list_all_for_customer' do
    it 'lists all unsubscribers for a customer' do
      stub = stub_request(:get, "#{api_base}/unsubscribers/all?customer=+1234567890")
        .to_return(status: 200, body: { items: [] }.to_json, headers: headers)

      service.list_all_for_customer('+1234567890')
      expect(stub).to have_been_requested
    end
  end
end
