require 'rails_helper'

describe PageCrawlerService do
  let(:html_link) { 'http://test.com' }
  let(:sitemap_link) { 'http://test.com/sitemap.xml' }
  let(:service_html) { described_class.new(html_link) }
  let(:service_sitemap) { described_class.new(sitemap_link) }

  let(:html_body) do
    <<-HTML
      <html>
        <head><title>Test Title</title></head>
        <body><a href="link1">Link 1</a><a href="link2">Link 2</a></body>
      </html>
    HTML
  end

  let(:sitemap_body) do
    <<-XML
      <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        <url><loc>http://test.com/link1</loc></url>
        <url><loc>http://test.com/link2</loc></url>
      </urlset>
    XML
  end

  before do
    stub_request(:get, html_link).to_return(body: html_body, status: 200)
    stub_request(:get, sitemap_link).to_return(body: sitemap_body, status: 200)
  end

  describe '#page_links' do
    context 'when a HTML page is given' do
      it 'returns all links on the page' do
        expect(service_html.page_links).to eq(Set.new(['http://test.com/link1', 'http://test.com/link2']))
      end
    end

    context 'when a sitemap is given' do
      it 'returns all links in the sitemap' do
        expect(service_sitemap.page_links).to eq(Set.new(['http://test.com/link1', 'http://test.com/link2']))
      end
    end
  end

  describe '#page_title' do
    it 'returns the title of the page' do
      expect(service_html.page_title).to eq('Test Title')
    end
  end

  describe '#body_text_content' do
    it 'returns the markdown converted body content of the page' do
      expect(service_html.body_text_content.strip).to eq('[Link 1](link1)[Link 2](link2)')
    end
  end
end
