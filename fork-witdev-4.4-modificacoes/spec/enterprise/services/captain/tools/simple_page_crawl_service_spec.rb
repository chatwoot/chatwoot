require 'rails_helper'

RSpec.describe Captain::Tools::SimplePageCrawlService do
  let(:base_url) { 'https://example.com' }
  let(:service) { described_class.new(base_url) }

  before do
    WebMock.disable_net_connect!
  end

  after do
    WebMock.allow_net_connect!
  end

  describe '#page_title' do
    context 'when title exists' do
      before do
        stub_request(:get, base_url)
          .to_return(body: '<html><head><title>Example Page</title></head></html>')
      end

      it 'returns the page title' do
        expect(service.page_title).to eq('Example Page')
      end
    end

    context 'when title does not exist' do
      before do
        stub_request(:get, base_url)
          .to_return(body: '<html><head></head></html>')
      end

      it 'returns nil' do
        expect(service.page_title).to be_nil
      end
    end
  end

  describe '#page_links' do
    context 'with HTML page' do
      let(:html_content) do
        <<~HTML
          <html>
            <body>
              <a href="/relative">Relative Link</a>
              <a href="https://external.com">External Link</a>
              <a href="#anchor">Anchor Link</a>
            </body>
          </html>
        HTML
      end

      before do
        stub_request(:get, base_url).to_return(body: html_content)
      end

      it 'extracts and absolutizes all links' do
        links = service.page_links
        expect(links).to include(
          'https://example.com/relative',
          'https://external.com',
          'https://example.com#anchor'
        )
      end
    end

    context 'with sitemap XML' do
      let(:sitemap_url) { 'https://example.com/sitemap.xml' }
      let(:sitemap_service) { described_class.new(sitemap_url) }
      let(:sitemap_content) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
            <url>
              <loc>https://example.com/page1</loc>
            </url>
            <url>
              <loc>https://example.com/page2</loc>
            </url>
          </urlset>
        XML
      end

      before do
        stub_request(:get, sitemap_url).to_return(body: sitemap_content)
      end

      it 'extracts links from sitemap' do
        links = sitemap_service.page_links
        expect(links).to contain_exactly(
          'https://example.com/page1',
          'https://example.com/page2'
        )
      end
    end
  end

  describe '#body_text_content' do
    let(:html_content) do
      <<~HTML
        <html>
          <body>
            <h1>Main Title</h1>
            <p>Some <strong>formatted</strong> content.</p>
            <ul>
              <li>List item 1</li>
              <li>List item 2</li>
            </ul>
          </body>
        </html>
      HTML
    end

    before do
      stub_request(:get, base_url).to_return(body: html_content)
      allow(ReverseMarkdown).to receive(:convert).and_return("# Main Title\n\nConverted markdown")
    end

    it 'converts body content to markdown' do
      expect(service.body_text_content).to eq("# Main Title\n\nConverted markdown")
      expect(ReverseMarkdown).to have_received(:convert).with(
        kind_of(Nokogiri::XML::Element),
        unknown_tags: :bypass,
        github_flavored: true
      )
    end
  end
end
