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

      it 'raises an error' do
        expect { described_class.new }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when API key is nil' do
      before do
        InstallationConfig.find_by(name: 'CAPTAIN_FIRECRAWL_API_KEY').update(value: nil)
      end

      it 'raises an error' do
        expect { described_class.new }.to raise_error(NoMethodError)
      end
    end

    context 'when API key is empty' do
      before do
        InstallationConfig.find_by(name: 'CAPTAIN_FIRECRAWL_API_KEY').update(value: '')
      end

      it 'raises an error' do
        expect { described_class.new }.to raise_error('Missing API key')
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

    let(:expected_headers) do
      {
        'Authorization' => "Bearer #{api_key}",
        'Content-Type' => 'application/json'
      }
    end

    context 'when the API call is successful' do
      before do
        stub_request(:post, 'https://api.firecrawl.dev/v1/crawl')
          .with(
            body: expected_payload,
            headers: expected_headers
          )
          .to_return(status: 200, body: '{"status": "success"}')
      end

      it 'makes a POST request with correct parameters' do
        service.perform(url, webhook_url, crawl_limit)

        expect(WebMock).to have_requested(:post, 'https://api.firecrawl.dev/v1/crawl')
          .with(
            body: expected_payload,
            headers: expected_headers
          )
      end

      it 'uses default crawl limit when not specified' do
        default_payload = expected_payload.gsub(crawl_limit.to_s, '10')

        stub_request(:post, 'https://api.firecrawl.dev/v1/crawl')
          .with(
            body: default_payload,
            headers: expected_headers
          )
          .to_return(status: 200, body: '{"status": "success"}')

        service.perform(url, webhook_url)

        expect(WebMock).to have_requested(:post, 'https://api.firecrawl.dev/v1/crawl')
          .with(
            body: default_payload,
            headers: expected_headers
          )
      end
    end

    context 'when the API call fails' do
      before do
        stub_request(:post, 'https://api.firecrawl.dev/v1/crawl')
          .to_raise(StandardError.new('Connection failed'))
      end

      it 'raises an error with the failure message' do
        expect { service.perform(url, webhook_url, crawl_limit) }
          .to raise_error('Failed to crawl URL: Connection failed')
      end
    end

    context 'when the API returns an error response' do
      before do
        stub_request(:post, 'https://api.firecrawl.dev/v1/crawl')
          .to_return(status: 422, body: '{"error": "Invalid URL"}')
      end

      it 'makes the request but does not raise an error' do
        expect { service.perform(url, webhook_url, crawl_limit) }.not_to raise_error

        expect(WebMock).to have_requested(:post, 'https://api.firecrawl.dev/v1/crawl')
          .with(
            body: expected_payload,
            headers: expected_headers
          )
      end
    end
  end
end
