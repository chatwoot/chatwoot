# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Aloo::WebScrapingService do
  let(:base_url) { 'https://example.com/page' }
  let(:html_content) do
    <<~HTML
      <!DOCTYPE html>
      <html>
        <head><title>Test Page</title></head>
        <body>
          <nav>Navigation</nav>
          <main>
            <h1>Main Content</h1>
            <p>This is the main content of the page.</p>
            <a href="/other-page">Link to other page</a>
          </main>
          <footer>Footer</footer>
        </body>
      </html>
    HTML
  end

  before do
    stub_request(:get, base_url).to_return(body: html_content, status: 200)
  end

  describe '#initialize' do
    it 'sets base_url' do
      service = described_class.new(url: base_url)
      expect(service.base_url).to eq(base_url)
    end

    it 'sets crawl_full_site flag' do
      service = described_class.new(url: base_url, crawl_full_site: true)
      expect(service.crawl_full_site).to be true
    end

    it 'extracts base domain' do
      service = described_class.new(url: 'https://www.example.com/path')
      expect(service.base_domain).to eq('example.com')
    end

    it 'handles www prefix' do
      service = described_class.new(url: 'https://www.example.com')
      expect(service.base_domain).to eq('example.com')
    end
  end

  describe '#perform' do
    context 'when crawl_full_site is false' do
      let(:service) { described_class.new(url: base_url, crawl_full_site: false) }

      it 'fetches single page' do
        result = service.perform

        expect(result[:pages].size).to eq(1)
      end

      it 'returns page content and title' do
        result = service.perform

        page = result[:pages].first
        expect(page[:title]).to eq('Test Page')
        expect(page[:content]).to include('Main Content')
      end

      it 'extracts main content area' do
        result = service.perform

        page = result[:pages].first
        expect(page[:content]).to include('main content')
        expect(page[:content]).not_to include('Navigation')
        expect(page[:content]).not_to include('Footer')
      end

      it 'handles HTTP errors' do
        stub_request(:get, base_url).to_return(status: 500)

        result = service.perform

        expect(result[:pages]).to be_empty
        expect(result[:errors].first[:error]).to include('HTTP 500')
      end
    end

    context 'when crawl_full_site is true' do
      let(:service) { described_class.new(url: base_url, crawl_full_site: true) }
      let(:other_page_url) { 'https://example.com/other-page' }
      let(:other_html) do
        <<~HTML
          <!DOCTYPE html>
          <html>
            <head><title>Other Page</title></head>
            <body><main>Other content</main></body>
          </html>
        HTML
      end

      before do
        stub_request(:get, other_page_url).to_return(body: other_html, status: 200)
      end

      it 'follows links on same domain' do
        result = service.perform

        expect(result[:pages].size).to eq(2)
      end

      it 'does not revisit URLs' do
        # The stub should only be called once per URL
        service.perform

        expect(a_request(:get, base_url)).to have_been_made.once
        expect(a_request(:get, other_page_url)).to have_been_made.once
      end
    end

    context 'when network error occurs' do
      before do
        stub_request(:get, base_url).to_timeout
      end

      it 'returns error in result' do
        service = described_class.new(url: base_url)
        result = service.perform

        expect(result[:pages]).to be_empty
        expect(result[:errors]).not_to be_empty
        expect(result[:errors].first[:url]).to eq(base_url)
      end
    end

    context 'with max limits' do
      let(:service) { described_class.new(url: base_url, crawl_full_site: true) }

      it 'respects MAX_PAGES' do
        # Create many linked pages
        html_with_many_links = <<~HTML
          <!DOCTYPE html>
          <html>
            <head><title>Start</title></head>
            <body>
              <main>
                #{(1..100).map { |i| "<a href='/page-#{i}'>Page #{i}</a>" }.join}
              </main>
            </body>
          </html>
        HTML

        stub_request(:get, base_url).to_return(body: html_with_many_links, status: 200)
        (1..100).each do |i|
          stub_request(:get, "https://example.com/page-#{i}")
            .to_return(body: "<html><body>Page #{i}</body></html>", status: 200)
        end

        result = service.perform

        expect(result[:pages].size).to be <= described_class::MAX_PAGES
      end
    end
  end

  describe 'content extraction' do
    let(:service) { described_class.new(url: base_url) }

    it 'removes script tags' do
      html = '<html><body><script>alert("bad")</script><main>Content</main></body></html>'
      stub_request(:get, base_url).to_return(body: html, status: 200)

      result = service.perform

      expect(result[:pages].first[:content]).not_to include('alert')
    end

    it 'removes nav/header/footer' do
      result = service.perform

      content = result[:pages].first[:content]
      expect(content).not_to include('Navigation')
      expect(content).not_to include('Footer')
    end

    it 'converts to markdown' do
      html = '<html><body><main><h1>Header</h1><p>Paragraph</p></main></body></html>'
      stub_request(:get, base_url).to_return(body: html, status: 200)

      result = service.perform

      content = result[:pages].first[:content]
      expect(content).to include('# Header')
    end

    it 'prefers main content area' do
      html = <<~HTML
        <html>
          <body>
            <div class="sidebar">Sidebar content</div>
            <main>Main content here</main>
          </body>
        </html>
      HTML
      stub_request(:get, base_url).to_return(body: html, status: 200)

      result = service.perform

      expect(result[:pages].first[:content]).to include('Main content')
    end
  end

  describe 'link extraction' do
    let(:service) { described_class.new(url: base_url, crawl_full_site: true) }

    it 'ignores external domains' do
      html = '<html><body><a href="https://other.com/page">External</a></body></html>'
      stub_request(:get, base_url).to_return(body: html, status: 200)

      result = service.perform

      expect(result[:pages].size).to eq(1)
    end

    it 'ignores javascript links' do
      html = '<html><body><a href="javascript:void(0)">JS Link</a></body></html>'
      stub_request(:get, base_url).to_return(body: html, status: 200)

      result = service.perform

      expect(result[:pages].size).to eq(1)
    end

    it 'ignores mailto links' do
      html = '<html><body><a href="mailto:test@example.com">Email</a></body></html>'
      stub_request(:get, base_url).to_return(body: html, status: 200)

      result = service.perform

      expect(result[:pages].size).to eq(1)
    end

    it 'removes fragment from URLs' do
      html = '<html><body><a href="/other-page#section">Link</a></body></html>'
      stub_request(:get, base_url).to_return(body: html, status: 200)
      stub_request(:get, 'https://example.com/other-page').to_return(body: '<html><body>Other Page</body></html>', status: 200)

      result = service.perform

      # Should crawl base_url and /other-page (with fragment removed)
      expect(result[:pages].size).to eq(2)
    end
  end
end
