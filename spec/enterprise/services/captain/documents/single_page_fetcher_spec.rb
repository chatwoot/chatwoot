require 'rails_helper'

RSpec.describe Captain::Documents::SinglePageFetcher do
  let(:url) { 'https://example.com/docs' }
  let(:spider) { instance_double(WebCrawling::BaseSpider) }

  before do
    allow(WebCrawling::Factory).to receive(:build).and_return(spider)
  end

  it 'returns normalized content from the configured spider' do
    allow(spider).to receive(:scrape).with(url: url).and_return(
      WebCrawling::Types::Page.new(url: url, title: 'Documentation', markdown: '# Documentation', status_code: 200)
    )

    expect(described_class.new(url).fetch).to have_attributes(
      success: true,
      title: 'Documentation',
      content: '# Documentation',
      error_code: nil
    )
  end

  it 'returns the normalized provider error' do
    allow(spider).to receive(:scrape).with(url: url).and_return(
      WebCrawling::Types::Page.new(url: url, status_code: 404, error_code: 'not_found')
    )

    expect(described_class.new(url).fetch).to have_attributes(success: false, error_code: 'not_found')
  end

  it 'rejects empty content' do
    allow(spider).to receive(:scrape).with(url: url).and_return(
      WebCrawling::Types::Page.new(url: url, title: 'Documentation', status_code: 200)
    )

    expect(described_class.new(url).fetch).to have_attributes(success: false, error_code: 'content_empty')
  end
end
