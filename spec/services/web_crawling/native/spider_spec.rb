require 'rails_helper'

RSpec.describe WebCrawling::Native::Spider do
  let(:url) { 'https://example.com' }

  describe '#discover' do
    before do
      stub_request(:get, url).to_return(
        body: <<~HTML
          <html>
            <body>
              <a href="/docs/getting-started">Docs</a>
              <a href="/help/contact">Help</a>
              <a href="/pricing">Pricing</a>
            </body>
          </html>
        HTML
      )
    end

    it 'filters and limits discovered links' do
      pages = described_class.new.discover(url: url, limit: 1, query: 'documentation help')

      expect(pages).to contain_exactly(
        WebCrawling::Types::DiscoveredPage.new(url: 'https://example.com/help/contact')
      )
    end
  end

  describe '#scrape' do
    before do
      stub_request(:get, url).to_return(
        status: 200,
        body: '<html><head><title>Example</title></head><body><h1>Hello</h1></body></html>'
      )
    end

    it 'returns a normalized page' do
      page = described_class.new.scrape(url: url)

      expect(page).to have_attributes(
        url: url,
        title: 'Example',
        status_code: 200,
        error_code: nil
      )
      expect(page.markdown).to include('Hello')
    end
  end
end
