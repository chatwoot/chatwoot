require 'rails_helper'

RSpec.describe Captain::Tools::FirecrawlService do
  let(:api_key) { 'test-api-key' }
  let(:url) { 'https://example.com' }
  let(:webhook_url) { 'https://webhook.example.com/callback' }
  let(:crawl_limit) { 15 }

  before do
    create(:installation_config, name: 'CAPTAIN_FIRECRAWL_API_KEY', value: api_key)
  end

  describe '#initialize' do
    context 'when API key is configured' do
      it 'initializes successfully' do
        expect { described_class.new }.not_to raise_error
      end
    end

    context 'when API key is missing' do
      before do
        InstallationConfig.find_by(name: 'CAPTAIN_FIRECRAWL_API_KEY').destroy
      end

      it 'raises an ArgumentError' do
        expect { described_class.new }.to raise_error(ArgumentError, 'Firecrawl API key not configured')
      end
    end
  end

  describe '#perform' do
    let(:service) { described_class.new }
    let(:expected_payload) do
      {
        url: url,
        maxDepth: 50,
        ignoreSitemap: false,
        limit: crawl_limit,
        webhook: webhook_url,
        scrapeOptions: {
          onlyMainContent: false,
          formats: ['markdown'],
          excludeTags: ['iframe']
        }
      }.to_json
    end

    context 'when the API call is successful' do
      before do
        stub_request(:post, 'https://api.firecrawl.dev/v1/crawl')
          .with(
            body: expected_payload,
            headers: {
              'Authorization' => "Bearer #{api_key}",
              'Content-Type' => 'application/json'
            }
          )
          .to_return(status: 200, body: '{"status": "success"}')
      end

      it 'makes a POST request with correct parameters' do
        service.perform(url, webhook_url, crawl_limit)

        expect(WebMock).to have_requested(:post, 'https://api.firecrawl.dev/v1/crawl')
          .with(
            body: expected_payload,
            headers: {
              'Authorization' => "Bearer #{api_key}",
              'Content-Type' => 'application/json'
            }
          )
      end
    end

    context 'when the API call fails' do
      before do
        stub_request(:post, 'https://api.firecrawl.dev/v1/crawl')
          .to_raise(StandardError.new('Connection failed'))
      end

      it 'raises an error' do
        expect { service.perform(url, webhook_url, crawl_limit) }
          .to raise_error(StandardError, 'Connection failed')
      end
    end

    context 'when the API returns an error response' do
      before do
        stub_request(:post, 'https://api.firecrawl.dev/v1/crawl')
          .to_return(status: 422, body: '{"error": "Invalid URL"}')
      end

      it 'raises a RuntimeError with details' do
        expect { service.perform(url, webhook_url, crawl_limit) }
          .to raise_error(RuntimeError, /Firecrawl API Error: 422/)
      end
    end
  end
end
