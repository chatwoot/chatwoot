# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Igaralead::HubClient do
  describe '.configured?' do
    it 'returns false when HUB_API_URL is not set' do
      with_modified_env(HUB_API_URL: '', HUB_API_KEY: 'key') do
        expect(described_class.configured?).to be false
      end
    end

    it 'returns false when HUB_API_KEY is not set' do
      with_modified_env(HUB_API_URL: 'https://hub.example.com', HUB_API_KEY: '') do
        expect(described_class.configured?).to be false
      end
    end

    it 'returns true when both are configured' do
      with_modified_env(HUB_API_URL: 'https://hub.example.com', HUB_API_KEY: 'key') do
        expect(described_class.configured?).to be true
      end
    end
  end

  describe '.get' do
    before do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('HUB_API_URL', anything).and_return('https://hub.example.com')
      allow(ENV).to receive(:fetch).with('HUB_API_KEY', anything).and_return('test-key')
    end

    it 'includes X-Api-Key header in requests' do
      stub = stub_request(:get, 'https://hub.example.com/api/test')
             .with(headers: { 'X-Api-Key' => 'test-key' })
             .to_return(status: 200, body: '{}')

      described_class.get('/api/test')
      expect(stub).to have_been_requested
    end

    it 'handles timeout gracefully' do
      stub_request(:get, 'https://hub.example.com/api/test')
        .to_timeout

      expect { described_class.get('/api/test') }.not_to raise_error
    end

    it 'handles connection failure gracefully' do
      stub_request(:get, 'https://hub.example.com/api/test')
        .to_raise(Faraday::ConnectionFailed)

      expect { described_class.get('/api/test') }.not_to raise_error
    end
  end
end
