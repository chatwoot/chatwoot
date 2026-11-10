require 'rails_helper'

RSpec.describe Sms::BandwidthTokenService do
  let(:config) { { 'account_id' => '123', 'client_id' => 'client', 'client_secret' => 'secret' } }
  let(:service) { described_class.new(config: config) }
  let(:url) { 'https://api.bandwidth.com/api/v1/oauth2/token' }
  let(:token_body) { { access_token: 'test-token', token_type: 'Bearer', expires_in: 3600 }.to_json }
  let(:cache) { ActiveSupport::Cache::MemoryStore.new }
  let(:request) do
    stub_request(:post, url).with(basic_auth: %w[client secret], body: { 'grant_type' => 'client_credentials' })
                            .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: token_body)
  end

  before { allow(Rails).to receive(:cache).and_return(cache) }

  it 'reuses the token and refreshes before expiry' do
    request
    expect(service.token).to eq('test-token')
    travel 3589.seconds do
      expect(service.token).to eq('test-token')
      expect(request).to have_been_requested.once
    end
    travel 3591.seconds do
      expect(service.token).to eq('test-token')
      expect(request).to have_been_requested.twice
    end
  end

  it 'bypasses the cache when verifying credentials' do
    request
    service.token
    service.token(force: true)
    expect(request).to have_been_requested.twice
  end

  it 'uses a new cache entry after credential rotation' do
    request
    service.token
    config['client_secret'] = 'rotated'
    rotated = stub_request(:post, url).with(basic_auth: %w[client rotated])
                                      .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: token_body)
    expect(service.token).to eq('test-token')
    expect(rotated).to have_been_requested.once
  end

  [400, 401, 403].each do |status|
    it "sanitizes credential rejection with HTTP #{status}" do
      stub_request(:post, url).to_return(status: status, body: 'sensitive provider response')
      expect { service.token }.to raise_error(CustomExceptions::Bandwidth::AuthenticationError) { |error|
        expect(error.message).not_to include('sensitive provider response')
        expect(error.cause).to be_nil
      }
    end
  end

  [429, 500, 503].each do |status|
    it "keeps HTTP #{status} retryable without exposing the response" do
      stub_request(:post, url).to_return(status: status, body: 'sensitive provider response')
      expect { service.token }.to raise_error(CustomExceptions::Bandwidth::TokenRequestError) { |error|
        expect(error.message).not_to include('sensitive provider response')
        expect(error.cause).to be_nil
      }
    end
  end

  it 'keeps timeouts retryable' do
    stub_request(:post, url).to_timeout
    expect { service.token }.to raise_error(CustomExceptions::Bandwidth::TokenRequestError)
  end
end
