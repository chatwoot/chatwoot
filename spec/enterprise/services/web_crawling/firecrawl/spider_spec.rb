require 'rails_helper'

RSpec.describe WebCrawling::Firecrawl::Spider do
  let(:api_key) { 'test-api-key' }
  let(:url) { 'https://example.com' }
  let(:spider) { described_class.new }

  before do
    create(:installation_config, name: 'CAPTAIN_FIRECRAWL_API_KEY', value: api_key)
  end

  describe '.configured?' do
    it 'reflects the Firecrawl configuration' do
      expect(described_class.configured?).to be(true)
    end
  end

  describe '#discover' do
    it 'returns normalized discovered pages' do
      map_data = instance_double(
        Firecrawl::Models::MapData,
        links: [{ 'url' => "#{url}/docs", 'title' => 'Docs', 'description' => 'Product documentation' }]
      )
      client = instance_double(Firecrawl::Client)
      allow(WebCrawling::Firecrawl::Configuration).to receive(:client).and_return(client)
      expect(client).to receive(:map) do |received_url, options|
        expect(received_url).to eq(url)
        expect(options).to have_attributes(limit: 10, search: 'documentation')
        map_data
      end

      expect(spider.discover(url: url, limit: 10, query: 'documentation')).to contain_exactly(
        WebCrawling::Types::DiscoveredPage.new(
          url: "#{url}/docs",
          title: 'Docs',
          description: 'Product documentation'
        )
      )
    end
  end

  describe '#scrape' do
    it 'returns a normalized page' do
      stub_request(:post, 'https://api.firecrawl.dev/v2/scrape').to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: {
          data: {
            markdown: '# Documentation',
            metadata: { title: 'Docs', sourceURL: "#{url}/docs", statusCode: 200 }
          }
        }.to_json
      )

      expect(spider.scrape(url: url)).to eq(
        WebCrawling::Types::Page.new(
          url: "#{url}/docs",
          title: 'Docs',
          markdown: '# Documentation',
          status_code: 200
        )
      )
    end

    it 'normalizes target page failures returned inside successful responses' do
      stub_request(:post, 'https://api.firecrawl.dev/v2/scrape').to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: { data: { metadata: { statusCode: 404 } } }.to_json
      )

      expect(spider.scrape(url: url)).to have_attributes(status_code: 404, error_code: 'not_found')
    end

    it 'normalizes Firecrawl API failures' do
      stub_request(:post, 'https://api.firecrawl.dev/v2/scrape').to_return(status: 403)

      expect(spider.scrape(url: url)).to have_attributes(status_code: 403, error_code: 'access_denied')
    end
  end

  describe '#scrape_many' do
    it 'normalizes batch documents' do
      document = instance_double(
        Firecrawl::Models::Document,
        markdown: '# Docs',
        metadata: { 'sourceURL' => "#{url}/docs", 'title' => 'Docs', 'statusCode' => 200 }
      )
      job = instance_double(Firecrawl::Models::BatchScrapeJob, data: [document])
      client = instance_double(Firecrawl::Client)
      allow(WebCrawling::Firecrawl::Configuration).to receive(:client).and_return(client)
      expect(client).to receive(:batch_scrape) do |urls, options|
        expect(urls).to eq(["#{url}/docs"])
        expect(options.options).to have_attributes(only_main_content: true)
        job
      end

      expect(spider.scrape_many(urls: ["#{url}/docs"])).to contain_exactly(
        WebCrawling::Types::Page.new(
          url: "#{url}/docs",
          title: 'Docs',
          markdown: '# Docs',
          status_code: 200
        )
      )
    end
  end

  describe '#crawl' do
    it 'returns a normalized crawl submission' do
      stub_request(:post, 'https://api.firecrawl.dev/v2/crawl').to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: { id: 'crawl-123', status: 'queued' }.to_json
      )

      expect(spider.crawl(url: url, limit: 20, callback_url: 'https://chatwoot.example.com/webhook')).to eq(
        WebCrawling::Types::CrawlSubmission.new(
          provider: :firecrawl,
          external_id: 'crawl-123',
          status: 'queued',
          metadata: { 'id' => 'crawl-123', 'status' => 'queued' }
        )
      )
    end

    it 'requires a callback URL' do
      expect { spider.crawl(url: url, limit: 20) }.to raise_error(ArgumentError, 'callback_url is required')
    end
  end
end
