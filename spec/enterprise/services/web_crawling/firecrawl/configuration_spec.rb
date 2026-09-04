require 'rails_helper'

RSpec.describe Firecrawl::Configuration do
  it 'delegates configuration checks to the web crawling provider' do
    allow(WebCrawling::Firecrawl::Configuration).to receive(:configured?).and_return(true)

    expect(described_class.configured?).to be(true)
  end
end
