require 'rails_helper'

describe Whatsapp::Ycloud::ApiClient do
  let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'ycloud', sync_templates: false, validate_provider_config: false) }
  let(:client) { described_class.new(whatsapp_channel: whatsapp_channel) }
  let(:api_base) { 'https://api.ycloud.com/v2' }

  describe '#get' do
    it 'sends GET request with correct headers' do
      stub = stub_request(:get, "#{api_base}/whatsapp/templates")
        .with(headers: { 'X-API-Key' => 'test_key', 'Content-Type' => 'application/json' })
        .to_return(status: 200, body: '{}')

      client.get('/whatsapp/templates')
      expect(stub).to have_been_requested
    end

    it 'passes query params' do
      stub = stub_request(:get, "#{api_base}/whatsapp/templates?page=1&limit=10")
        .to_return(status: 200, body: '{}')

      client.get('/whatsapp/templates', page: 1, limit: 10)
      expect(stub).to have_been_requested
    end
  end

  describe '#post' do
    it 'sends POST request with JSON body' do
      stub = stub_request(:post, "#{api_base}/whatsapp/messages/send")
        .with(
          headers: { 'X-API-Key' => 'test_key', 'Content-Type' => 'application/json' },
          body: { to: '+1234567890', type: 'text' }.to_json
        )
        .to_return(status: 200, body: '{"id":"msg_001"}')

      client.post('/whatsapp/messages/send', { to: '+1234567890', type: 'text' })
      expect(stub).to have_been_requested
    end
  end

  describe '#patch' do
    it 'sends PATCH request with JSON body' do
      stub = stub_request(:patch, "#{api_base}/whatsapp/templates/hello/en")
        .with(body: { category: 'UTILITY' }.to_json)
        .to_return(status: 200, body: '{}')

      client.patch('/whatsapp/templates/hello/en', { category: 'UTILITY' })
      expect(stub).to have_been_requested
    end
  end

  describe '#delete' do
    it 'sends DELETE request' do
      stub = stub_request(:delete, "#{api_base}/whatsapp/templates/hello")
        .to_return(status: 200, body: '{}')

      client.delete('/whatsapp/templates/hello')
      expect(stub).to have_been_requested
    end
  end

  describe '.verify_signature' do
    let(:webhook_secret) { 'whsec_test_secret_123' }
    let(:raw_body) { '{"type":"whatsapp.inbound_message.received"}' }
    let(:timestamp) { '1700000000' }

    it 'returns true for a valid signature' do
      expected_sig = OpenSSL::HMAC.hexdigest('SHA256', webhook_secret, "#{timestamp}.#{raw_body}")
      signature_header = "t=#{timestamp},s=#{expected_sig}"

      expect(described_class.verify_signature(raw_body, signature_header, webhook_secret)).to be true
    end

    it 'returns false for an invalid signature' do
      signature_header = "t=#{timestamp},s=invalidsignature"

      expect(described_class.verify_signature(raw_body, signature_header, webhook_secret)).to be false
    end

    it 'returns false for blank signature header' do
      expect(described_class.verify_signature(raw_body, '', webhook_secret)).to be false
    end

    it 'returns false for blank webhook secret' do
      expect(described_class.verify_signature(raw_body, 't=123,s=abc', '')).to be false
    end

    it 'returns false for malformed signature header' do
      expect(described_class.verify_signature(raw_body, 'malformed', webhook_secret)).to be false
    end
  end

  describe '#api_base_path' do
    it 'uses default YCloud URL' do
      expect(client.api_base_path).to eq('https://api.ycloud.com/v2')
    end

    it 'uses custom URL from env' do
      with_modified_env YCLOUD_BASE_URL: 'https://sandbox.ycloud.com/v2' do
        expect(client.api_base_path).to eq('https://sandbox.ycloud.com/v2')
      end
    end
  end
end
