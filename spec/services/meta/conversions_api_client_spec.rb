require 'rails_helper'

RSpec.describe Meta::ConversionsApiClient do
  subject(:client) { described_class.new(access_token: token, dataset_id: dataset_id, api_version: api_version) }

  # 44 chars, all token-safe -> matches SENSITIVE_PATTERN and must be redacted.
  let(:token) { "EAAG#{'x' * 40}" }
  let(:dataset_id) { 'DS123' }
  let(:api_version) { 'v22.0' }
  let(:endpoint) { "https://graph.facebook.com/#{api_version}/#{dataset_id}/events" }
  let(:event) { { 'event_name' => 'Purchase', 'event_time' => 123, 'ctwa_clid' => 'CLID1' } }

  describe '#post_events' do
    it 'posts the events wrapped in a data array and returns an ok result on success' do
      stub = stub_request(:post, endpoint)
             .with(query: hash_including('access_token' => token), body: { data: [event] }.to_json)
             .to_return(status: 200, body: '{"events_received":1}', headers: { 'Content-Type' => 'application/json' })

      result = client.post_events([event])

      expect(stub).to have_been_requested
      expect(result.ok).to be(true)
      expect(result.http_code).to eq(200)
      expect(result.error).to be_nil
      expect(result.body).to include('events_received')
    end

    it 'redacts any token-shaped substring echoed back in an error body' do
      stub_request(:post, endpoint)
        .to_return(status: 400, body: %({"error":{"message":"Invalid OAuth access token #{token}"}}))

      result = client.post_events([event])

      expect(result.ok).to be(false)
      expect(result.http_code).to eq(400)
      expect(result.error).to include('<REDACTED>')
      expect(result.error).not_to include(token)
    end

    it 'never surfaces the token when the HTTP call raises' do
      allow(HTTParty).to receive(:post).and_raise(StandardError.new("network down token=#{token}"))

      result = client.post_events([event])

      expect(result.ok).to be(false)
      expect(result.http_code).to be_nil
      expect(result.error).to include('<REDACTED>')
      expect(result.error).not_to include(token)
    end
  end

  describe 'api_version resolution' do
    it 'falls back to the shared WhatsApp API version when none is given' do
      allow(GlobalConfigService).to receive(:load).with('WHATSAPP_API_VERSION', described_class::DEFAULT_API_VERSION).and_return('v20.0')
      resolved = described_class.new(access_token: token, dataset_id: dataset_id)
      stub = stub_request(:post, "https://graph.facebook.com/v20.0/#{dataset_id}/events").to_return(status: 200, body: '{}')

      resolved.post_events([event])

      expect(stub).to have_been_requested
    end
  end
end
