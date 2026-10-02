require 'rails_helper'

RSpec.describe WebCrawling::ContextDev::Spider do
  let(:api_key) { 'context-test-key' }
  let(:url) { 'https://example.com/docs' }
  let(:spider) { described_class.new }
  let(:headers) do
    {
      'Authorization' => "Bearer #{api_key}",
      'Content-Type' => 'application/json'
    }
  end

  before do
    create(:installation_config, name: 'CONTEXT_DEV_API_KEY', value: api_key)
  end

  describe '.configured?' do
    it 'reflects the Context.dev configuration' do
      expect(described_class.configured?).to be(true)
    end
  end

  describe '#discover' do
    it 'returns normalized sitemap results' do
      stub_request(:get, 'https://api.context.dev/v1/web/scrape/sitemap')
        .with(
          query: { domain: 'example.com', maxLinks: 20, search: 'help articles' },
          headers: headers
        )
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: { success: true, urls: ["#{url}/getting-started"] }.to_json
        )

      expect(spider.discover(url: url, limit: 20, query: 'help articles')).to contain_exactly(
        WebCrawling::Types::DiscoveredPage.new(url: "#{url}/getting-started")
      )
    end
  end

  describe '#scrape' do
    it 'returns a normalized Markdown page' do
      stub_request(:get, 'https://api.context.dev/v1/web/scrape/markdown')
        .with(
          query: { url: url, useMainContentOnly: true, maxAgeMs: 0 },
          headers: headers
        )
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: {
            success: true,
            url: url,
            markdown: '# Documentation',
            metadata: { finalUrl: "#{url}/", title: 'Documentation' }
          }.to_json
        )

      expect(spider.scrape(url: url)).to eq(
        WebCrawling::Types::Page.new(
          url: "#{url}/",
          title: 'Documentation',
          markdown: '# Documentation',
          status_code: 200
        )
      )
    end

    it 'normalizes Context.dev failures' do
      stub_request(:get, 'https://api.context.dev/v1/web/scrape/markdown')
        .with(query: { url: url, useMainContentOnly: true, maxAgeMs: 0 }, headers: headers)
        .to_return(
          status: 404,
          headers: { 'Content-Type' => 'application/json' },
          body: { error_code: 'NOT_FOUND', message: 'Page not found' }.to_json
        )

      expect(spider.scrape(url: url)).to have_attributes(status_code: 404, error_code: 'not_found')
    end
  end

  describe '#crawl' do
    it 'submits an asynchronous Markdown crawl' do
      callback_url = 'https://chatwoot.example.com/context-webhook'
      request_id = 'crawl-request-123'
      expected_body = {
        input: {
          mode: 'crawl',
          data: {
            format: 'markdown',
            source: {
              type: 'start_url',
              url: url,
              controls: { maxUrls: 50, maxDepth: 50, followSubdomains: false }
            },
            options: { useMainContentOnly: true }
          }
        },
        webhookUrl: callback_url
      }.to_json
      stub_request(:post, 'https://api.context.dev/v1/batch/submit')
        .with(body: expected_body, headers: headers.merge('Idempotency-Key' => request_id))
        .to_return(
          status: 202,
          headers: { 'Content-Type' => 'application/json' },
          body: { id: 'batch-123', status: 'queued', webhook_secret: 'secret' }.to_json
        )

      expect(spider.crawl(url: url, limit: 50, callback_url: callback_url, request_id: request_id)).to eq(
        WebCrawling::Types::CrawlSubmission.new(
          provider: :context_dev,
          external_id: 'batch-123',
          status: 'queued',
          metadata: { 'id' => 'batch-123', 'status' => 'queued', 'webhook_secret' => 'secret' }
        )
      )
    end

    it 'requires a callback URL' do
      expect { spider.crawl(url: url, limit: 50) }.to raise_error(ArgumentError, 'callback_url is required')
    end
  end

  describe '#fetch_results' do
    it 'normalizes successful and failed records with pagination' do
      stub_request(:get, 'https://api.context.dev/v1/batch/batch-123/results')
        .with(query: { limit: 100, cursor: 'next-page' }, headers: headers)
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: {
            data: [
              {
                url: url,
                final_url: "#{url}/",
                status: 'ok',
                http_status: 200,
                markdown: '# Docs',
                metadata: { title: 'Docs' }
              },
              { url: "#{url}/missing", status: 'error', error_code: 'NOT_FOUND' }
            ],
            has_more: true,
            next_cursor: 'last-page'
          }.to_json
        )

      results = spider.fetch_results(batch_id: 'batch-123', cursor: 'next-page')

      expect(results).to have_attributes(has_more: true, next_cursor: 'last-page')
      expect(results.pages).to contain_exactly(
        WebCrawling::Types::Page.new(
          url: "#{url}/",
          title: 'Docs',
          markdown: '# Docs',
          status_code: 200
        ),
        WebCrawling::Types::Page.new(url: "#{url}/missing", error_code: 'not_found')
      )
    end
  end

  describe '#batch_status' do
    it 'returns the current batch status' do
      stub_request(:get, 'https://api.context.dev/v1/batch/batch-123')
        .with(query: {}, headers: headers)
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: { id: 'batch-123', status: 'running' }.to_json
        )

      expect(spider.batch_status(batch_id: 'batch-123')).to eq('running')
    end
  end
end
